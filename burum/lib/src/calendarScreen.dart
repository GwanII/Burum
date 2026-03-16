import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

// 💡 [개조 완료] 내용(content) 필드가 새롭게 추가된 거대한 상자!
class EventDateRange {
  DateTime start;
  DateTime end;
  EventDateRange(this.start, this.end);
}

class CalendarEvent {
  final String title;
  final String content; // 💡 새롭게 추가된 내용(메모) 필드!!!!!
  final Color color;
  final String location;
  final int alarmMinutes;
  final List<EventDateRange> dateRanges;

  CalendarEvent(this.title, this.content, this.color, this.location, this.alarmMinutes, this.dateRanges);
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final Color mainYellow = const Color(0xFFFFF59D);
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  final Map<DateTime, List<CalendarEvent>> _events = {};

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  // 🚀 [백엔드로 초거대 짐을 싸서 날려 보내는 대포!!!!!]
  Future<void> _saveEventToDatabase(CalendarEvent newEvent) async {
    final String baseUrl = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
    final url = Uri.parse('$baseUrl/api/createCalendarEvent'); 

    // 날짜들을 JSON 배열로 예쁘게 변환!
    List<Map<String, String>> dateRangesJson = newEvent.dateRanges.map((range) {
      return {
        "start": "${range.start.year}-${range.start.month.toString().padLeft(2, '0')}-${range.start.day.toString().padLeft(2, '0')} ${range.start.hour.toString().padLeft(2, '0')}:${range.start.minute.toString().padLeft(2, '0')}:00",
        "end": "${range.end.year}-${range.end.month.toString().padLeft(2, '0')}-${range.end.day.toString().padLeft(2, '0')} ${range.end.hour.toString().padLeft(2, '0')}:${range.end.minute.toString().padLeft(2, '0')}:00",
      };
    }).toList();

    final requestData = {
      "user_id": 1,
      "title": newEvent.title,
      "content": newEvent.content, // 💡 백엔드로 보낼 내용(메모) 추가 완료!!!!!
      "location": newEvent.location,
      "color": newEvent.color.value.toRadixString(16), 
      "alarm_minutes": newEvent.alarmMinutes,
      "date_ranges": dateRangesJson, 
    };

    try {
      final response = await http.post(
        url, headers: {"Content-Type": "application/json"}, body: jsonEncode(requestData),
      );

      if (response.statusCode == 201) {
        print("🎉 DB에 강력한 일정 등록 성공!!!!!");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('서버 창고에 일정이 무사히 저장되었소!!!!!')));
        }
      } else {
        print("적의 방어! 상태 코드: ${response.statusCode}");
      }
    } catch (e) {
      print("통신망 단절 에러: $e");
    }
  }

  // 📝 [프리미엄 일정 추가 창 띄우기 마법!!!!!]
  void _showAddMemoDialog(DateTime day) async {
    final CalendarEvent? newEvent = await showDialog<CalendarEvent>(
      context: context,
      // 🚨 (주의) showDialog에는 isScrollControlled 마법을 쓰지 않소! 지워버렸소!!!!!
      builder: (context) => AddEventDialog(initialDate: day),
    );

    if (newEvent != null) {
      setState(() {
        for (var range in newEvent.dateRanges) {
          for (int i = 0; i <= range.end.difference(range.start).inDays; i++) {
            DateTime current = range.start.add(Duration(days: i));
            final normalizedDay = DateTime(current.year, current.month, current.day);
            
            if (_events[normalizedDay] == null) _events[normalizedDay] = [];
            _events[normalizedDay]!.add(newEvent);
          }
        }
      });
      await _saveEventToDatabase(newEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: mainYellow,
        elevation: 0,
        title: const Text('캘린더', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1), lastDay: DateTime.utc(2030, 12, 31), focusedDay: _focusedDay,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              headerStyle: const HeaderStyle(
                titleCentered: true, formatButtonVisible: false,
                leftChevronIcon: Icon(Icons.arrow_left, size: 40, color: Colors.black),
                rightChevronIcon: Icon(Icons.arrow_right, size: 40, color: Colors.black),
              ),
              daysOfWeekHeight: 40, rowHeight: 110, eventLoader: _getEventsForDay,
              calendarBuilders: CalendarBuilders(
                headerTitleBuilder: (context, day) => Text('${day.year}. ${day.month.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                dowBuilder: (context, day) {
                  const weekdayNames = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
                  return Center(child: Text(weekdayNames[day.weekday]!, style: TextStyle(color: day.weekday == 7 ? Colors.red : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)));
                },
                defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(day),
                todayBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: true),
                outsideBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isOutside: true),
                markerBuilder: (context, day, events) => const SizedBox(),
              ),
              onPageChanged: (focusedDay) { _focusedDay = focusedDay; },
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 80, height: 80,
        child: FloatingActionButton(
          onPressed: () => _showAddMemoDialog(_focusedDay),
          backgroundColor: Colors.white, elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40), side: const BorderSide(color: Colors.grey, width: 1)),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, color: Colors.black, size: 36), Text('일정 추가', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))]),
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, {bool isToday = false, bool isOutside = false}) {
    final events = _getEventsForDay(day);
    Color textColor = Colors.black;
    if (day.weekday == DateTime.sunday) textColor = Colors.red;
    if (isOutside) textColor = Colors.grey.shade400;

    return GestureDetector(
      onDoubleTap: () => _showAddMemoDialog(day),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5), color: isToday ? Colors.yellow.withOpacity(0.1) : Colors.transparent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(left: 6.0, top: 4.0), child: Text('${day.day}', style: TextStyle(color: textColor, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, fontSize: 16))),
            const SizedBox(height: 2),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 2), itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 3), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: event.color.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: event.color, width: 1.5))),
                        const SizedBox(width: 4),
                        Expanded(child: Text(event.title, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 🌟🌟🌟 [신규 마법진] 초특급 프리미엄 일정 추가 다이얼로그 🌟🌟🌟
// =========================================================================
class AddEventDialog extends StatefulWidget {
  final DateTime initialDate;
  const AddEventDialog({super.key, required this.initialDate});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController(); // 💡 내용 입력을 위한 새로운 컨트롤러!
  final TextEditingController _locationController = TextEditingController();
  
  final List<Color> _availableColors = [const Color(0xFFFFCCBC), const Color(0xFFC8E6C9), const Color(0xFFBBDEFB), const Color(0xFFE1BEE7), const Color(0xFFFFF9C4)];
  late Color _selectedColor;
  
  int _alarmMinutes = 15; 
  List<EventDateRange> _dateRanges = [];

  @override
  void initState() {
    super.initState();
    _selectedColor = _availableColors[0];
    _dateRanges.add(EventDateRange(
      DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, 10, 0),
      DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, 11, 0)
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose(); // 💡 메모리 누수를 막기 위해 청소!
    _locationController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    DateTime? date = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (date == null) return null;
    TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('위대한 일정 추가!!!!!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 16),
            
            // 1. 제목 입력
            TextField(
              controller: _titleController,
              decoration: InputDecoration(hintText: '일정 제목', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            
            // 💡 2. 내용(메모) 입력 (길게 적을 수 있도록 여러 줄 허용!)
            TextField(
              controller: _contentController,
              maxLines: 3, // 세 줄 크기로 넉넉하게!
              decoration: InputDecoration(
                hintText: '일정 내용(상세 메모)', 
                filled: true, 
                fillColor: Colors.grey.shade100, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              ),
            ),
            const SizedBox(height: 12),

            // 3. 장소 입력
            TextField(
              controller: _locationController,
              decoration: InputDecoration(hintText: '장소 (선택)', prefixIcon: const Icon(Icons.location_on, color: Colors.grey), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 16),

            // 4. 색상 선택
            const Text('캡슐 색상', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _availableColors.map((c) => GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: _selectedColor == c ? Colors.black : Colors.transparent, width: 2)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // 5. 알람 선택
            const Text('알람 설정', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            DropdownButton<int>(
              value: _alarmMinutes,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 0, child: Text('정각')),
                DropdownMenuItem(value: 10, child: Text('10분 전')),
                DropdownMenuItem(value: 15, child: Text('15분 전')),
                DropdownMenuItem(value: 30, child: Text('30분 전')),
                DropdownMenuItem(value: 60, child: Text('1시간 전')),
              ],
              onChanged: (val) => setState(() => _alarmMinutes = val!),
            ),
            const SizedBox(height: 16),

            // 6. 다중 날짜 설정!!!!!
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('날짜 및 시간', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _dateRanges.add(EventDateRange(DateTime.now(), DateTime.now().add(const Duration(hours: 1))));
                    });
                  },
                  icon: const Icon(Icons.add, size: 16, color: Colors.blue),
                  label: const Text('날짜 추가', style: TextStyle(color: Colors.blue)),
                )
              ],
            ),
            ..._dateRanges.asMap().entries.map((entry) {
              int index = entry.key;
              EventDateRange range = entry.value;
              String startStr = "${range.start.month}/${range.start.day} ${range.start.hour.toString().padLeft(2, '0')}:${range.start.minute.toString().padLeft(2, '0')}";
              String endStr = "${range.end.month}/${range.end.day} ${range.end.hour.toString().padLeft(2, '0')}:${range.end.minute.toString().padLeft(2, '0')}";

              return Container(
                margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          DateTime? newStart = await _pickDateTime(range.start);
                          if (newStart != null) setState(() => range.start = newStart);
                        },
                        child: Text("시작: $startStr", style: const TextStyle(fontSize: 13, color: Colors.black87, decoration: TextDecoration.underline)),
                      ),
                    ),
                    const Text(" ~ "),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          DateTime? newEnd = await _pickDateTime(range.end);
                          if (newEnd != null) setState(() => range.end = newEnd);
                        },
                        child: Text("종료: $endStr", style: const TextStyle(fontSize: 13, color: Colors.black87, decoration: TextDecoration.underline)),
                      ),
                    ),
                    if (_dateRanges.length > 1) 
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                        onPressed: () => setState(() => _dateRanges.removeAt(index)),
                      )
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // 7. 저장 / 취소 버튼
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey)))),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFF59D), elevation: 0),
                    onPressed: () {
                      if (_titleController.text.isEmpty) return;
                      // 💡 완성된 일정을 포장해서 바깥 화면으로 던져주오!!!!! (content 추가 완료!)
                      final newEvent = CalendarEvent(
                        _titleController.text, 
                        _contentController.text, // 💡 새로 추가된 내용!
                        _selectedColor, 
                        _locationController.text, 
                        _alarmMinutes, 
                        _dateRanges
                      );
                      Navigator.pop(context, newEvent);
                    },
                    child: const Text('저장', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}