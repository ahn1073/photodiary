// firestore_database_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';

// 다이어리 모델 클래스 (Firestore 버전)
class DiaryModel {
  String? id;
  String title;
  String content;
  Uint8List imgTopLeft;
  Uint8List imgTopRight;
  Uint8List imgBtmLeft;
  Uint8List imgBtmRight;
  int date;

  DiaryModel({
    this.id,
    required this.title,
    required this.content,
    required this.imgTopLeft,
    required this.imgTopRight,
    required this.imgBtmLeft,
    required this.imgBtmRight,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imgTopLeft': imgTopLeft,
      'imgTopRight': imgTopRight,
      'imgBtmLeft': imgBtmLeft,
      'imgBtmRight': imgBtmRight,
      'date': date,
    };
  }

  factory DiaryModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return DiaryModel(
      id: documentId,
      title: data['title'] as String,
      content: data['content'] as String,
      imgTopLeft: Uint8List.fromList(List<int>.from(data['imgTopLeft'])),
      imgTopRight: Uint8List.fromList(List<int>.from(data['imgTopRight'])),
      imgBtmLeft: Uint8List.fromList(List<int>.from(data['imgBtmLeft'])),
      imgBtmRight: Uint8List.fromList(List<int>.from(data['imgBtmRight'])),
      date: data['date'] as int,
    );
  }
}

class FirestoreDatabaseHelper {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> insertDiary(DiaryModel diary) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('diaries')
        .add(diary.toMap());
  }

  // 현재 회원의 모든 다이어리 데이터를 가져옴 (최신순 정렬)
  // 다이어리 데이터를 가져올 때 currentUser가 null인 경우를 처리합니다.
  Future<List<DiaryModel>> getAllDiaries() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return [];
    }

    String userId = currentUser.uid;
    QuerySnapshot snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('diaries')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return DiaryModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  Future<void> updateDiary(DiaryModel diary) async {
    if (diary.id == null) return;
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('diaries')
        .doc(diary.id)
        .update(diary.toMap());
  }

  Future<void> deleteDiary(String diaryId) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('diaries')
        .doc(diaryId)
        .delete();
  }
}
