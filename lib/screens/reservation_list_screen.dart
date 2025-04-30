import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application_1/models/reservation_item.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key});

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  late Future<List<Reservation>> reservationFuture;
  late String baseUrl;

  @override
  void initState() {
    super.initState();
    baseUrl = dotenv.get("BaseUrl");
    reservationFuture = fetchReservations(
      1,
    ); // TODO: Replace with actual user ID
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
      default:
        return criteria;
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
                      reservations.map((reservation) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
