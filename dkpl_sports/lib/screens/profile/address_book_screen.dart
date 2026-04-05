import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/user_session.dart';
import '../../services/local_address_service.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  final _session = UserSession();

  Future<List<Map<String, dynamic>>> _loadAddresses() {
    final uid = _session.uid;
    if (uid == null) return Future.value([]);
    return LocalAddressService.instance.getAddresses(uid);
  }

  Future<void> _addAddress() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool setDefault = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thêm địa chỉ mới',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Checkbox(
                        value: setDefault,
                        onChanged: (val) => setState(() {
                          setDefault = val ?? false;
                        }),
                        activeColor: AppColors.primaryBlue,
                      );
                    },
                  ),
                  const Text('Đặt làm địa chỉ mặc định'),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      phoneCtrl.text.trim().isEmpty ||
                      addressCtrl.text.trim().isEmpty) {
                    return;
                  }
                  final uid = _session.uid;
                  if (uid != null) {
                    final address = {
                      'id': 'addr_${DateTime.now().millisecondsSinceEpoch}',
                      'fullName': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'detail': addressCtrl.text.trim(),
                      'isDefault': setDefault,
                    };
                    await LocalAddressService.instance.addAddress(
                      uid: uid,
                      address: address,
                    );
                    if (setDefault) {
                      await LocalAddressService.instance.setDefault(
                        uid: uid,
                        addressId: address['id'].toString(),
                      );
                    }
                  }
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Lưu địa chỉ'),
              ),
            ],
          ),
        );
      },
    );
    setState(() {});
  }

  Future<void> _setDefault(
    Map<String, dynamic> address,
  ) async {
    final uid = _session.uid;
    if (uid == null) return;
    await LocalAddressService.instance.setDefault(
      uid: uid,
      addressId: address['id'].toString(),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final uid = _session.uid;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Địa chỉ nhận hàng',
          style: TextStyle(color: AppColors.textDark),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: uid == null
          ? const Center(
              child: Text(
                'Vui lòng đăng nhập để quản lý địa chỉ.',
                style: TextStyle(color: AppColors.textLight),
              ),
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadAddresses(),
              builder: (context, snapshot) {
                final addresses = snapshot.data ?? [];
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (addresses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Chưa có địa chỉ nào. Hãy thêm địa chỉ để đặt hàng nhanh hơn.',
                          style: TextStyle(color: AppColors.textLight),
                        ),
                      ),
                    ...addresses.map((address) {
                      final isDefault = address['isDefault'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        address['fullName'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isDefault)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryBlue
                                                .withOpacity(.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Text(
                                            'Mặc định',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    address['phone'] ?? '',
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    address['detail'] ?? '',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _setDefault(address),
                              child: const Text('Địa chỉ mặc định'),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _addAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Thêm địa chỉ'),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
