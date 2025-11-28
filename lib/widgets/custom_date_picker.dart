import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const CustomDatePicker({
    super.key,
    this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + increment);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateSelected(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF001F1D), // Darker background for the card
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildWeekDays(),
          const SizedBox(height: 20),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('MMMM yyyy').format(_currentMonth).toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFFAFFB5),
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => _changeMonth(-1),
              child: const Icon(Icons.chevron_left,
                  color: Color(0xFFFAFFB5), size: 24),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _changeMonth(1),
              child: const Icon(Icons.chevron_right,
                  color: Color(0xFFFAFFB5), size: 24),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekDays() {
    final days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map((day) => SizedBox(
                width: 35,
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: Color(0xFFFAFFB5),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth =
        DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    // Calculate days from previous month to fill the first row
    final prevMonthDays = firstWeekday - 1;

    // Ensure we show at least a few days from next month if needed to complete the grid visually
    // The user's image shows 5 rows, sometimes 6. Let's just fill the grid.

    // Let's generate a list of DateTime objects for the grid
    final List<DateTime?> gridDates = [];

    // Previous month days
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final daysInPrevMonth =
        DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
    for (int i = 0; i < prevMonthDays; i++) {
      // We don't really need to show previous month dates based on the design,
      // but typically calendars do. The user's image shows "1 2 3 4 5" at the end,
      // which are next month. It doesn't show previous month at the start explicitly
      // in the image (it starts with 1), but that's because Dec 1 2022 was a Thursday.
      // Wait, Dec 1 2022 was a Thursday. The image shows 1 on Monday?
      // Let's look at the image again.
      // Image: Dec 2022. 1 is on Monday.
      // Real Dec 2022: Dec 1 was Thursday.
      // The image is a mock.
      // I should implement REAL calendar logic.

      // If I want to match the "grid" feel, I should probably fill with empty or prev month.
      // Standard behavior is to show prev month days dimmed.
      gridDates.add(DateTime(prevMonth.year, prevMonth.month,
          daysInPrevMonth - prevMonthDays + i + 1));
    }

    // Current month days
    for (int i = 1; i <= daysInMonth; i++) {
      gridDates.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    // Next month days to fill the remaining slots of the last row
    final remainingSlots = 7 - (gridDates.length % 7);
    if (remainingSlots < 7) {
      final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      for (int i = 1; i <= remainingSlots; i++) {
        gridDates.add(DateTime(nextMonth.year, nextMonth.month, i));
      }
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 5,
      ),
      itemCount: gridDates.length,
      itemBuilder: (context, index) {
        final date = gridDates[index];
        if (date == null) return const SizedBox();

        final isCurrentMonth = date.month == _currentMonth.month;
        final isSelected = DateUtils.isSameDay(date, _selectedDate);

        return GestureDetector(
          onTap: () {
            // Allow selecting dates from prev/next month too, which jumps to that month?
            // Or just select it. Let's just select it.
            _selectDate(date);
            if (!isCurrentMonth) {
              setState(() {
                _currentMonth = DateTime(date.year, date.month);
              });
            }
          },
          child: _buildDayCell(
            date.day.toString(),
            isSelected: isSelected,
            isCurrentMonth: isCurrentMonth,
          ),
        );
      },
    );
  }

  Widget _buildDayCell(String day,
      {bool isSelected = false, bool isCurrentMonth = true}) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFAFFB5) : Colors.transparent,
        shape: BoxShape.circle,
        border: isSelected || !isCurrentMonth
            ? null
            : Border.all(color: const Color(0xFFFAFFB5), width: 1.5),
      ),
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            color: isSelected
                ? Colors.black
                : !isCurrentMonth
                    ? const Color(0xFF004D4A) // Darker teal for next/prev month
                    : const Color(0xFFFAFFB5),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
