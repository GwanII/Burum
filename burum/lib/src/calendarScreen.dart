import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart'; 
import '../dio_client.dart';

class EventDateRange {
  DateTime start;
  DateTime end;
  EventDateRange(this.start, this.end);
}

class CalendarEvent {
  final int? id; 
  final String title;
  final String content; 
  final Color color;
  final String location;
  final int alarmMinutes;
  final List<EventDateRange> dateRanges;

  CalendarEvent({
    this.id, 
    required this.title, 
    required this.content, 
    required this.color, 
    required this.location, 
    required this.alarmMinutes, 
    required this.dateRanges
  });
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

  @override
  void initState() {
    super.initState();
    _fetchEventsFromDatabase(); 
  }

  Future<void> _fetchEventsFromDatabase() async {
    try {
      final response = await DioClient.instance.get('${Config.baseUrl}/api/calendar');

      if (response.statusCode == 200) {
        final data = response.data; 
        if (data['success'] == true) {
          final List<dynamic> fetchedEvents = data['events'];
          
          setState(() {
            _events.clear(); 
            
            for (var e in fetchedEvents) {
              try {
                String colorStr = e['color'] ?? 'FF90B2AB';
                Color eventColor = Color(int.parse(colorStr.replaceAll('#', 'FF'), radix: 16));

                List<EventDateRange> ranges = [];
                var schedulesRaw = e['schedules'];
                List<dynamic> schedulesList = schedulesRaw is String ? jsonDecode(schedulesRaw) : schedulesRaw;
                
                for (var s in schedulesList) {
                  ranges.add(EventDateRange(DateTime.parse(s['start']), DateTime.parse(s['end'])));
                }

                int alarmMin = 0;
                if (e['alarm'] == '10') alarmMin = 10;
                else if (e['alarm'] == '15') alarmMin = 15;
                else if (e['alarm'] == '30') alarmMin = 30;
                else if (e['alarm'] == '60') alarmMin = 60;

                final newEvent = CalendarEvent(
                  id: e['id'], 
                  title: e['title'], 
                  content: e['content'] ?? '', 
                  color: eventColor, 
                  location: e['location'] ?? '', 
                  alarmMinutes: alarmMin, 
                  dateRanges: ranges
                );

                for (var range in ranges) {
                  for (int i = 0; i <= range.end.difference(range.start).inDays; i++) {
                    DateTime current = range.start.add(Duration(days: i));
                    final normalizedDay = DateTime(current.year, current.month, current.day);
                    if (_events[normalizedDay] == null) _events[normalizedDay] = [];
                    _events[normalizedDay]!.add(newEvent);
                  }
                }
              } catch (e) {
                // 파싱 에러 무시
              }
            }
          });
        }
      }
    } catch (e) {
      print("일정 불러오기 실패: $e");
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Future<void> _saveEventToDatabase(CalendarEvent newEvent) async {
    List<Map<String, String>> dateRangesJson = newEvent.dateRanges.map((range) {
      return {
        "start": "${range.start.year}-${range.start.month.toString().padLeft(2, '0')}-${range.start.day.toString().padLeft(2, '0')} ${range.start.hour.toString().padLeft(2, '0')}:${range.start.minute.toString().padLeft(2, '0')}:00",
        "end": "${range.end.year}-${range.end.month.toString().padLeft(2, '0')}-${range.end.day.toString().padLeft(2, '0')} ${range.end.hour.toString().padLeft(2, '0')}:${range.end.minute.toString().padLeft(2, '0')}:00",
      };
    }).toList();

    final requestData = {
      "title": newEvent.title,
      "content": newEvent.content,
      "location": newEvent.location,
      "color": newEvent.color.value.toRadixString(16), 
      "alarm": newEvent.alarmMinutes.toString(), 
      "schedules": dateRangesJson, 
    };

    try {
      final response = await DioClient.instance.post(
        '${Config.baseUrl}/api/calendar', 
        data: requestData,
      );

      if (response.statusCode == 201) {
        await _fetchEventsFromDatabase();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('서버 창고에 일정이 무사히 저장되었소!!!!!')));
        }
      }
    } catch (e) {
      print("통신망 단절 에러: $e");
    }
  }

  Future<void> _deleteEvents(List<CalendarEvent> eventsToDelete, DateTime day) async {
    List<int> idsToDelete = eventsToDelete.where((e) => e.id != null).map((e) => e.id!).toList();

    if (idsToDelete.isEmpty) {
      setState(() {
        for (var event in eventsToDelete) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          _events[normalizedDay]?.remove(event);
        }
      });
      return;
    }

    try {
      final requestData = { "ids": idsToDelete };

      final response = await DioClient.instance.delete(
        '${Config.baseUrl}/api/calendar',
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          for (var event in eventsToDelete) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            _events[normalizedDay]?.remove(event);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${eventsToDelete.length}개의 일정을 완벽히 소각했소!!!!!')));
        }
      } else {
        print("삭제 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("삭제 통신 에러: $e");
    }
  }

  void _showAddMemoDialog(DateTime day) async {
    final CalendarEvent? newEvent = await showDialog<CalendarEvent>(
      context: context,
      builder: (context) => AddEventDialog(initialDate: day),
    );

    if (newEvent != null) {
      await _saveEventToDatabase(newEvent);
    }
  }

  void _showDailyEventsSheet(DateTime day) {
    bool isDeleteMode = false; 
    Set<CalendarEvent> selectedEvents = {}; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final events = _getEventsForDay(day);

            return DraggableScrollableSheet(
              initialChildSize: 0.45, 
              minChildSize: 0.25,     
              maxChildSize: 0.85,     
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 12, bottom: 16),
                              width: 50, height: 5,
                              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          
                          Expanded(
                            child: events.isEmpty
                                ? const Center(child: Text('이 날은 일정이 없소!!!!!', style: TextStyle(color: Colors.grey, fontSize: 16)))
                                : ListView.separated(
                                    controller: scrollController,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    itemCount: events.length,
                                    separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
                                    itemBuilder: (context, index) {
                                      final event = events[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 50, height: 50,
                                              decoration: BoxDecoration(color: event.color.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                                              child: Icon(Icons.event_note, color: event.color, size: 26),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(color: event.color.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                                                        child: const Text('일정', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(event.content.isEmpty ? '내용 없음' : event.content, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            ),
                                            if (isDeleteMode)
                                              Checkbox(
                                                value: selectedEvents.contains(event),
                                                activeColor: Colors.redAccent,
                                                onChanged: (bool? value) {
                                                  setModalState(() {
                                                    if (value == true) selectedEvents.add(event);
                                                    else selectedEvents.remove(event);
                                                  });
                                                },
                                              )
                                            else
                                              const Icon(Icons.check, color: Colors.grey, size: 24),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                      
                      // 🌟 터치 한 번에 탈출! 직관적인 닫기(X) 버튼 추가! 🌟
                      Positioned(
                        right: 12,
                        top: 12,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54, size: 28),
                          onPressed: () {
                            Navigator.pop(context); 
                          },
                        ),
                      ),

                      Positioned(
                        right: 20,
                        bottom: 20,
                        child: isDeleteMode
                            ? Row(
                                children: [
                                  FloatingActionButton.extended(
                                    heroTag: 'cancel_btn',
                                    elevation: 0,
                                    backgroundColor: Colors.grey.shade200,
                                    onPressed: () {
                                      setModalState(() {
                                        isDeleteMode = false;
                                        selectedEvents.clear();
                                      });
                                    },
                                    label: const Text('취소', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  FloatingActionButton.extended(
                                    heroTag: 'delete_confirm_btn',
                                    elevation: 0,
                                    backgroundColor: Colors.redAccent,
                                    onPressed: selectedEvents.isEmpty ? null : () {
                                      _deleteEvents(selectedEvents.toList(), day);
                                      Navigator.pop(context); 
                                    },
                                    label: Text('${selectedEvents.length}개 삭제', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    icon: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                ],
                              )
                            : SizedBox(
                                width: 70, height: 70,
                                child: FloatingActionButton(
                                  heroTag: 'delete_event_fab',
                                  elevation: 0,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    side: BorderSide(color: Colors.grey.shade400, width: 1),
                                  ),
                                  onPressed: () {
                                    if (events.isEmpty) return; 
                                    setModalState(() {
                                      isDeleteMode = true; 
                                    });
                                  },
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.remove, color: Colors.black, size: 28),
                                      Text('일정 삭제', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, 
      
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
              firstDay: DateTime.utc(2020, 1, 1), 
              lastDay: DateTime.utc(2030, 12, 31), 
              focusedDay: _focusedDay,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              
              // 🌟🌟🌟 요괴 퇴치 마법 1: 화면을 빈틈없이 꽉 채우게 하옵니다! (오버플로우 해결) 🌟🌟🌟
              shouldFillViewport: true, 
              
              // 🌟🌟🌟 요괴 퇴치 마법 2: 어떤 달이든 6주(7x6) 사이즈로 튼튼하게 고정! 🌟🌟🌟
              sixWeekMonthsEnforced: true, 
              
              headerStyle: const HeaderStyle(
                titleCentered: true, formatButtonVisible: false,
                leftChevronIcon: Icon(Icons.arrow_left, size: 40, color: Colors.black),
                rightChevronIcon: Icon(Icons.arrow_right, size: 40, color: Colors.black),
              ),
              daysOfWeekHeight: 40, 
              eventLoader: _getEventsForDay,
              
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; 
                });
                _showDailyEventsSheet(selectedDay);
              },

              calendarBuilders: CalendarBuilders(
                headerTitleBuilder: (context, day) => Text('${day.year}. ${day.month.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                dowBuilder: (context, day) {
                  const weekdayNames = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
                  Color dowColor = Colors.black;
                  if (day.weekday == DateTime.saturday) dowColor = Colors.blue;
                  if (day.weekday == DateTime.sunday) dowColor = Colors.red;
                  return Center(child: Text(weekdayNames[day.weekday]!, style: TextStyle(color: dowColor, fontWeight: FontWeight.bold, fontSize: 16)));
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
          onPressed: () => _showAddMemoDialog(_selectedDay ?? _focusedDay),
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
    if (day.weekday == DateTime.saturday) textColor = Colors.blue;
    if (day.weekday == DateTime.sunday) textColor = Colors.red;
    if (isOutside) textColor = Colors.grey.shade400;

    return Opacity(
      opacity: isOutside ? 0.4 : 1.0,
      child: GestureDetector(
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
                  physics: const ClampingScrollPhysics(), 
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
      ),
    );
  }
}

class AddEventDialog extends StatefulWidget {
  final DateTime initialDate;
  const AddEventDialog({super.key, required this.initialDate});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController(); 
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
      DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, 12, 0),
      DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, 13, 0)
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose(); 
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
            
            TextField(
              controller: _titleController,
              decoration: InputDecoration(hintText: '일정 제목', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _contentController,
              maxLines: 3, 
              decoration: InputDecoration(
                hintText: '일정 내용(상세 메모)', 
                filled: true, 
                fillColor: Colors.grey.shade100, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _locationController,
              decoration: InputDecoration(hintText: '장소 (선택)', prefixIcon: const Icon(Icons.location_on, color: Colors.grey), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 16),

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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('날짜 및 시간', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _dateRanges.add(EventDateRange(
                        DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, 12, 0),
                        DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, 13, 0)
                      ));
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

            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey)))),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFF59D), elevation: 0),
                    onPressed: () {
                      if (_titleController.text.isEmpty) return;
                      final newEvent = CalendarEvent(
                        title: _titleController.text, 
                        content: _contentController.text,
                        color: _selectedColor, 
                        location: _locationController.text, 
                        alarmMinutes: _alarmMinutes, 
                        dateRanges: _dateRanges
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