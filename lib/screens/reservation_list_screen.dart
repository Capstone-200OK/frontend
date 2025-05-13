import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application_1/models/reservation_item.dart';
import 'package:flutter_application_1/models/folder_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/screens/file_reservation_screen.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key});

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  Future<List<Reservation>> reservationFuture = Future.value([]);
  late String baseUrl;
  late int? userId;

  @override
  void initState() {
    super.initState();
    baseUrl = dotenv.get("BaseUrl");

    // ✅ context 접근은 addPostFrameCallback 안에서
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId != null) {
        setState(() {
          reservationFuture = fetchReservations(userId!);
        });
      } else {
        print("❗ userId가 null입니다. 예약 목록을 불러오지 않습니다.");
      }
    });
  }

  Future<List<Reservation>> fetchReservations(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/scheduledTask/list/$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Reservation.fromJson(json)).toList();
    } else {
      throw Exception('예약 목록을 불러오지 못했습니다.');
    }
  }

  String formatInterval(String interval) {
    switch (interval) {
      case 'DAILY':
        return '매일';
      case 'WEEKLY':
        return '매주';
      case 'MONTHLY':
        return '매월';
      default:
        return interval;
    }
  }

  String formatCriteria(String criteria) {
    switch (criteria) {
      case 'TYPE':
        return '유형';
      case 'NAME':
        return '이름';
      case 'DATE':
        return '날짜';
      case 'CONTENT':
        return '내용';
      default:
        return criteria;
    }
  }

  Future<void> deleteReservation(int taskId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/scheduledTask/delete/$taskId'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('예약이 삭제되었습니다.')),
      );
      setState(() {
        reservationFuture = fetchReservations(userId!);  // ✅ 새로고침
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '자동 분류 예약 목록',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'APPLESDGOTHICNEOEB',
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              color: Color(0xFF455A64),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: const [
                  Expanded(child: Center(child: Text('관리 폴더', style: TextStyle(fontSize: 14, fontFamily: 'APPLESDGOTHICNEOEB', color: Colors.white),))),
                  Expanded(child: Center(child: Text('목적지 폴더', style: TextStyle(fontSize: 14, fontFamily: 'APPLESDGOTHICNEOEB', color: Colors.white),))),
                  Expanded(child: Center(child: Text('주기', style: TextStyle(fontSize: 14, fontFamily: 'APPLESDGOTHICNEOEB', color: Colors.white),))),
                  Expanded(child: Center(child: Text('정리 기준', style: TextStyle(fontSize: 14, fontFamily: 'APPLESDGOTHICNEOEB', color: Colors.white),))),
                ],
              ),
            ),
            const Divider(height: 1),
            FutureBuilder<List<Reservation>>(
              future: reservationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('오류 발생: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('예약된 항목이 없습니다.'),
                  );
                }

                final reservations = snapshot.data!;
                return Column(
                  children:
                      reservations.map<Widget>((reservation) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: GestureDetector(
                            onSecondaryTapDown: (details) async {
                              final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                              final positionRect = RelativeRect.fromLTRB(
                                details.globalPosition.dx,
                                details.globalPosition.dy,
                                overlay.size.width - details.globalPosition.dx,
                                overlay.size.height - details.globalPosition.dy,
                              );

                              final selected = await showMenu<String>(
                                context: context,
                                position: positionRect,
                                color: Color(0xFFECEFF1),
                                items: [
                                  PopupMenuItem(
                                    value: 'modify',
                                    child: Row(
                                      children: const [
                                        Icon(Icons.edit, size: 16, color: Colors.black54),
                                        SizedBox(width: 8),
                                        Text('수정', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: const [
                                        Icon(Icons.delete, size: 16, color: Colors.black54),
                                        SizedBox(width: 8),
                                        Text('삭제', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              );

                              if (selected == 'delete') {
                                await deleteReservation(reservation.taskId);
                              } else if (selected == 'modify') {
                                showDialog(
                                  context: context,
                                  builder: (context) => FileReservationScreen(
                                    mode: 'modify',
                                    reservation: reservation,
                                  ),
                                );
                              }
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      '${reservation.previousFoldername}',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      '${reservation.newFoldername}',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      formatInterval(reservation.interval),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      formatCriteria(reservation.criteria),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
