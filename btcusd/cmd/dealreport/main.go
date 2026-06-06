package main

import (
	"bufio"
	"encoding/csv"
	"flag"
	"fmt"
	"io"
	"math"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"
)

type deal struct {
	DealID     uint64
	Time       time.Time
	Symbol     string
	Entry      string
	Type       string
	Volume     float64
	Price      float64
	Profit     float64
	Commission float64
	Swap       float64
	Magic      uint64
	PositionID uint64
	Comment    string
	Reason     string
}

type tradeStat struct {
	PositionID uint64
	Symbol     string
	NetPnL     float64
	CloseTime  time.Time
}

func main() {
	const defaultIgnoreFile = "config/ignored_trade_ids.txt"

	inputPath := flag.String("input", "", "Path to CodexTrendPullbackEA-deals.tsv")
	fromDate := flag.String("from", "", "Filter from date, format: YYYY-MM-DD")
	toDate := flag.String("to", "", "Filter to date, format: YYYY-MM-DD")
	symbol := flag.String("symbol", "", "Only include one symbol, for example BTCUSD")
	magic := flag.Uint64("magic", 0, "Only include one magic number")
	startingBalance := flag.Float64("starting-balance", 0, "Optional starting balance for ROI")
	ignoreFile := flag.String("ignore-file", defaultIgnoreFile, "Optional path to a text file of deal/position IDs to ignore")
	flag.Parse()

	if *inputPath == "" {
		fmt.Fprintln(os.Stderr, "missing required flag: -input")
		os.Exit(1)
	}

	from, err := parseDateBoundary(*fromDate, true)
	if err != nil {
		exitf("invalid -from value: %v", err)
	}

	to, err := parseDateBoundary(*toDate, false)
	if err != nil {
		exitf("invalid -to value: %v", err)
	}

	deals, err := loadDeals(*inputPath)
	if err != nil {
		exitf("failed to load deals: %v", err)
	}

	ignoredIDs, err := loadIgnoredIDs(*ignoreFile, defaultIgnoreFile)
	if err != nil {
		exitf("failed to load ignored IDs: %v", err)
	}

	filtered := filterDeals(deals, from, to, strings.TrimSpace(*symbol), *magic, ignoredIDs)
	if len(filtered) == 0 {
		fmt.Println("No matching deals found.")
		return
	}

	positionStats := summarizePositions(filtered)
	netPnL, grossProfit, grossLoss := sumPnL(filtered)
	wins, losses, breakeven, avgWin, avgLoss, profitFactor := summarizeOutcomes(positionStats)
	winRate := 0.0
	if wins+losses > 0 {
		winRate = float64(wins) / float64(wins+losses) * 100
	}

	firstTime := filtered[0].Time
	lastTime := filtered[0].Time
	for _, d := range filtered[1:] {
		if d.Time.Before(firstTime) {
			firstTime = d.Time
		}
		if d.Time.After(lastTime) {
			lastTime = d.Time
		}
	}

	fmt.Printf("File: %s\n", *inputPath)
	fmt.Printf("Range: %s -> %s\n", firstTime.Format("2006-01-02 15:04:05"), lastTime.Format("2006-01-02 15:04:05"))
	if len(ignoredIDs) > 0 {
		fmt.Printf("Ignored IDs: %d\n", len(ignoredIDs))
	}
	fmt.Printf("Deals: %d\n", len(filtered))
	fmt.Printf("Closed positions: %d\n", len(positionStats))
	fmt.Printf("Net PnL: %.2f\n", netPnL)
	fmt.Printf("Gross profit: %.2f\n", grossProfit)
	fmt.Printf("Gross loss: %.2f\n", grossLoss)
	fmt.Printf("Wins: %d\n", wins)
	fmt.Printf("Losses: %d\n", losses)
	fmt.Printf("Breakeven: %d\n", breakeven)
	fmt.Printf("Win rate: %.2f%%\n", winRate)
	fmt.Printf("Average win: %.2f\n", avgWin)
	fmt.Printf("Average loss: %.2f\n", avgLoss)
	if math.IsInf(profitFactor, 1) {
		fmt.Printf("Profit factor: inf\n")
	} else {
		fmt.Printf("Profit factor: %.2f\n", profitFactor)
	}
	if *startingBalance > 0 {
		fmt.Printf("Return on starting balance: %.2f%%\n", netPnL/(*startingBalance)*100)
	}

	sort.Slice(positionStats, func(i, j int) bool {
		return positionStats[i].CloseTime.After(positionStats[j].CloseTime)
	})

	fmt.Println()
	fmt.Println("Recent closed positions:")
	limit := min(10, len(positionStats))
	for i := 0; i < limit; i++ {
		p := positionStats[i]
		fmt.Printf("%s  position=%d  symbol=%s  net=%.2f\n",
			p.CloseTime.Format("2006-01-02 15:04:05"),
			p.PositionID,
			p.Symbol,
			p.NetPnL,
		)
	}
}

func loadDeals(path string) ([]deal, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	reader := csv.NewReader(file)
	reader.Comma = '\t'
	reader.FieldsPerRecord = -1

	var deals []deal
	line := 0
	for {
		record, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}
		line++
		if len(record) == 0 {
			continue
		}
		if line == 1 && strings.EqualFold(strings.TrimSpace(record[0]), "deal_id") {
			continue
		}

		d, err := parseDeal(record)
		if err != nil {
			return nil, fmt.Errorf("line %d: %w", line, err)
		}
		deals = append(deals, d)
	}

	if len(deals) == 0 {
		return nil, fmt.Errorf("file contains no deals")
	}

	return deals, nil
}

func parseDeal(record []string) (deal, error) {
	if len(record) < 14 {
		return deal{}, fmt.Errorf("expected 14 columns, got %d", len(record))
	}

	parsedTime, err := time.ParseInLocation("2006.01.02 15:04:05", strings.TrimSpace(record[1]), time.Local)
	if err != nil {
		return deal{}, fmt.Errorf("invalid deal time %q: %w", record[1], err)
	}

	return deal{
		DealID:     mustUint(record[0]),
		Time:       parsedTime,
		Symbol:     strings.TrimSpace(record[2]),
		Entry:      strings.ToUpper(strings.TrimSpace(record[3])),
		Type:       strings.ToUpper(strings.TrimSpace(record[4])),
		Volume:     mustFloat(record[5]),
		Price:      mustFloat(record[6]),
		Profit:     mustFloat(record[7]),
		Commission: mustFloat(record[8]),
		Swap:       mustFloat(record[9]),
		Magic:      mustUint(record[10]),
		PositionID: mustUint(record[11]),
		Comment:    strings.TrimSpace(record[12]),
		Reason:     strings.ToUpper(strings.TrimSpace(record[13])),
	}, nil
}

func filterDeals(deals []deal, from time.Time, to time.Time, symbol string, magic uint64, ignoredIDs map[uint64]struct{}) []deal {
	var filtered []deal
	for _, d := range deals {
		if isIgnoredDeal(d, ignoredIDs) {
			continue
		}
		if !from.IsZero() && d.Time.Before(from) {
			continue
		}
		if !to.IsZero() && d.Time.After(to) {
			continue
		}
		if symbol != "" && !strings.EqualFold(d.Symbol, symbol) {
			continue
		}
		if magic != 0 && d.Magic != magic {
			continue
		}
		filtered = append(filtered, d)
	}
	return filtered
}

func loadIgnoredIDs(path string, defaultPath string) (map[uint64]struct{}, error) {
	ignored := make(map[uint64]struct{})
	path = strings.TrimSpace(path)
	if path == "" {
		return ignored, nil
	}

	file, err := os.Open(path)
	if err != nil {
		if os.IsNotExist(err) && path == defaultPath {
			return ignored, nil
		}
		return nil, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		id, err := strconv.ParseUint(line, 10, 64)
		if err != nil {
			return nil, fmt.Errorf("invalid ignored ID %q: %w", line, err)
		}
		ignored[id] = struct{}{}
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return ignored, nil
}

func isIgnoredDeal(d deal, ignoredIDs map[uint64]struct{}) bool {
	if len(ignoredIDs) == 0 {
		return false
	}
	if _, ok := ignoredIDs[d.DealID]; ok {
		return true
	}
	if d.PositionID != 0 {
		if _, ok := ignoredIDs[d.PositionID]; ok {
			return true
		}
	}
	return false
}

func summarizePositions(deals []deal) []tradeStat {
	byPosition := make(map[uint64]*tradeStat)
	for _, d := range deals {
		if d.PositionID == 0 {
			continue
		}
		stat := byPosition[d.PositionID]
		if stat == nil {
			stat = &tradeStat{
				PositionID: d.PositionID,
				Symbol:     d.Symbol,
			}
			byPosition[d.PositionID] = stat
		}
		stat.NetPnL += d.Profit + d.Commission + d.Swap
		if isClosingEntry(d.Entry) && d.Time.After(stat.CloseTime) {
			stat.CloseTime = d.Time
		}
	}

	var positions []tradeStat
	for _, stat := range byPosition {
		if stat.CloseTime.IsZero() {
			continue
		}
		positions = append(positions, *stat)
	}
	return positions
}

func summarizeOutcomes(positions []tradeStat) (wins, losses, breakeven int, avgWin, avgLoss, profitFactor float64) {
	var winSum float64
	var lossSum float64

	for _, stat := range positions {
		switch {
		case stat.NetPnL > 0:
			wins++
			winSum += stat.NetPnL
		case stat.NetPnL < 0:
			losses++
			lossSum += math.Abs(stat.NetPnL)
		default:
			breakeven++
		}
	}

	if wins > 0 {
		avgWin = winSum / float64(wins)
	}
	if losses > 0 {
		avgLoss = -(lossSum / float64(losses))
	}
	if lossSum == 0 {
		profitFactor = math.Inf(1)
	} else {
		profitFactor = winSum / lossSum
	}

	return wins, losses, breakeven, avgWin, avgLoss, profitFactor
}

func sumPnL(deals []deal) (netPnL, grossProfit, grossLoss float64) {
	for _, d := range deals {
		net := d.Profit + d.Commission + d.Swap
		netPnL += net
		if net > 0 {
			grossProfit += net
		} else if net < 0 {
			grossLoss += net
		}
	}
	return netPnL, grossProfit, grossLoss
}

func isClosingEntry(entry string) bool {
	switch strings.ToUpper(strings.TrimSpace(entry)) {
	case "OUT", "OUT_BY", "INOUT":
		return true
	default:
		return false
	}
}

func parseDateBoundary(value string, start bool) (time.Time, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return time.Time{}, nil
	}

	parsed, err := time.ParseInLocation("2006-01-02", value, time.Local)
	if err != nil {
		return time.Time{}, err
	}
	if !start {
		parsed = parsed.Add(23*time.Hour + 59*time.Minute + 59*time.Second)
	}
	return parsed, nil
}

func mustUint(value string) uint64 {
	parsed, err := strconv.ParseUint(strings.TrimSpace(value), 10, 64)
	if err != nil {
		exitf("invalid uint value %q: %v", value, err)
	}
	return parsed
}

func mustFloat(value string) float64 {
	parsed, err := strconv.ParseFloat(strings.TrimSpace(value), 64)
	if err != nil {
		exitf("invalid float value %q: %v", value, err)
	}
	return parsed
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func exitf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}
