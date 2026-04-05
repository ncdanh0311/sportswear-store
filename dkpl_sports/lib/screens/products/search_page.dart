import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart'; // Đổi đường dẫn cho đúng
import 'filter_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchCtrl = TextEditingController();
  List<String> history = ["Giày bóng đá", "Bóng rổ", "Phụ kiện"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: _buildSearchBar(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Lịch sử tìm kiếm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: history.map((h) {
                return Chip(
                  label: Text(h, style: const TextStyle(color: AppColors.textDark)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            const Text("Gợi ý hôm nay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),
            Expanded(child: _buildResultGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(border: Border.all(color: AppColors.primaryBlue, width: 2), borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: searchCtrl, decoration: const InputDecoration(hintText: "Tìm kiếm...", border: InputBorder.none))),
          IconButton(icon: const Icon(Icons.tune, color: AppColors.textDark), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FilterPage()))),
          Container(
            width: 50, height: double.infinity,
            decoration: const BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.only(topRight: Radius.circular(28), bottomRight: Radius.circular(28))),
            child: IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
          ),
        ],
      ),
    );
  }

  Widget _buildResultGrid() {
    return GridView.builder(
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, mainAxisSpacing: 12, crossAxisSpacing: 12),
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: Column(
            children: [
              Expanded(child: Container(padding: const EdgeInsets.all(8), child: Image.asset("assets/images/bongda.jpg", fit: BoxFit.contain))),
              Text("Sản phẩm $index", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}