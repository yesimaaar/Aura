import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // ==================== CHATS ====================

  /// Obtiene la referencia a la colección de chats del usuario actual
  CollectionReference<Map<String, dynamic>> get _userChatsCollection {
    if (_userId == null) throw Exception('Usuario no autenticado');
    return _firestore.collection('users').doc(_userId).collection('chats');
  }

  /// Crea un nuevo chat y retorna su ID
  Future<String> createChat({String? title}) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final docRef = await _userChatsCollection.add({
      'title': title ?? 'Nuevo chat',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
    });

    return docRef.id;
  }

  /// Obtiene todos los chats del usuario actual
  Stream<List<ChatSession>> getChats() {
    if (_userId == null) return Stream.value([]);

    return _userChatsCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatSession(
          id: doc.id,
          title: data['title'] ?? 'Chat',
          lastMessage: data['lastMessage'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  /// Actualiza el título de un chat
  Future<void> updateChatTitle(String chatId, String title) async {
    if (_userId == null) return;

    await _userChatsCollection.doc(chatId).update({
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina un chat y todos sus mensajes
  Future<void> deleteChat(String chatId) async {
    if (_userId == null) return;

    // Eliminar todos los mensajes del chat
    final messagesSnapshot = await _userChatsCollection
        .doc(chatId)
        .collection('messages')
        .get();

    for (final doc in messagesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Eliminar el chat
    await _userChatsCollection.doc(chatId).delete();
  }

  // ==================== MENSAJES ====================

  /// Obtiene los mensajes de un chat específico
  Stream<List<ChatMessage>> getMessages(String chatId) {
    if (_userId == null) return Stream.value([]);

    return _userChatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          id: doc.id,
          content: data['content'] ?? '',
          isUser: data['isUser'] ?? true,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          imageBase64: data['imageBase64'],
        );
      }).toList();
    });
  }

  /// Agrega un mensaje a un chat
  Future<void> addMessage(String chatId, ChatMessage message) async {
    if (_userId == null) return;

    await _userChatsCollection.doc(chatId).collection('messages').add({
      'content': message.content,
      'isUser': message.isUser,
      'timestamp': FieldValue.serverTimestamp(),
      'imageBase64': message.imageBase64,
    });

    // Actualizar el último mensaje y fecha del chat
    String preview = message.content;
    if (preview.length > 50) {
      preview = '${preview.substring(0, 50)}...';
    }

    await _userChatsCollection.doc(chatId).update({
      'lastMessage': message.isUser ? preview : 'Aura: $preview',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== DATOS DE USUARIO ====================

  /// Guarda o actualiza los datos del usuario
  Future<void> saveUserData(Map<String, dynamic> data) async {
    if (_userId == null) return;

    await _firestore.collection('users').doc(_userId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Obtiene los datos del usuario
  Future<Map<String, dynamic>?> getUserData() async {
    if (_userId == null) return null;

    final doc = await _firestore.collection('users').doc(_userId).get();
    return doc.data();
  }

  // ==================== ORGANIZACIÓN ====================

  /// Guarda los datos de organización del usuario
  Future<void> saveOrganizationData(Map<String, dynamic> data) async {
    if (_userId == null) return;

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('organization')
        .doc('data')
        .set(data, SetOptions(merge: true));
  }

  /// Obtiene los datos de organización del usuario
  Future<Map<String, dynamic>?> getOrganizationData() async {
    if (_userId == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('organization')
        .doc('data')
        .get();
    return doc.data();
  }
}

/// Modelo para sesiones de chat
class ChatSession {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });
}
