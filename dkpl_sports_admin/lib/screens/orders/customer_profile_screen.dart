import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CustomerProfileScreen extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final String address;
  final String? userId;

  const CustomerProfileScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.userId,
  });

  String formatMoney(num value) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin khách hàng'),
      ),
      body: Column(
        children: [
          /// ===== HEADER =====
          FutureBuilder<DocumentSnapshot>(
            future: userId == null
                ? null
                : FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, snapshot) {
              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final displayName =
                  (userData?['fullName'] ?? userData?['name'] ?? name).toString();
              final displayPhone =
                  (userData?['phone'] ?? userData?['user_phone'] ?? phone).toString();
              final displayEmail =
                  (userData?['email'] ?? userData?['user_email'] ?? email).toString();
              final displayAddress =
                  (userData?['address'] ?? address).toString();

              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.withOpacity(0.1),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      child: Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(displayPhone),
                    Text(displayEmail),
                    Text(displayAddress),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          /// ===== DANH SÁCH ĐƠN =====
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: userId != null
                  ? FirebaseFirestore.instance
                      .collection('orders')
                      .where('user_id', isEqualTo: userId)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('orders')
                      .where('phone', isEqualTo: phone)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                double totalSpent = 0;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalSpent += (data['total'] ?? 0);
                }

                return Column(
                  children: [
                    /// ===== TỔNG TIỀN =====
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'Tổng chi tiêu: ${formatMoney(totalSpent)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),

                    /// ===== LIST =====
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;

                          return ListTile(
                            leading: const Icon(Icons.shopping_bag),
                            title: Text('Đơn: ${docs[index].id}'),
                            subtitle:
                                Text('💰 ${formatMoney(data['total'] ?? 0)}'),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
