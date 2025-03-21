import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class UpdateProductScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const UpdateProductScreen(
      {super.key, required this.productId, required this.productData});

  @override
  _UpdateProductScreenState createState() => _UpdateProductScreenState();
}

class _UpdateProductScreenState extends State<UpdateProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _idController =
        TextEditingController(text: widget.productData['idsanpham']);
    _categoryController =
        TextEditingController(text: widget.productData['loaisp']);

    _priceController = TextEditingController(
      text: NumberFormat("#,###", "vi_VN").format(widget.productData['gia']),
    );

    if (widget.productData['hinhanh'] != null &&
        widget.productData['hinhanh'].isNotEmpty) {
      _imageBytes = base64Decode(widget.productData['hinhanh']);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  void _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        int gia = int.parse(_priceController.text.replaceAll(".", ""));

        await _firestore.collection('products').doc(widget.productId).update({
          'idsanpham': _idController.text,
          'loaisp': _categoryController.text,
          'gia': gia,
          'hinhanh': _imageBytes != null
              ? base64Encode(_imageBytes!)
              : widget.productData['hinhanh'],
          // 'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cập nhật sản phẩm thành công!")),
        );

        Navigator.pop(context);
      } catch (e) {
        print("Lỗi khi cập nhật sản phẩm: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chỉnh sửa sản phẩm"),
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Ảnh sản phẩm
            Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _imageBytes!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 50, color: Colors.grey),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Chọn ảnh",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),

            SizedBox(height: 10),

            // Form nhập liệu
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _idController,
                    decoration: InputDecoration(labelText: "Tên sản phẩm *"),
                    validator: (value) =>
                        value!.isEmpty ? "Vui lòng nhập tên sản phẩm" : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _categoryController,
                    decoration: InputDecoration(labelText: "Loại sản phẩm *"),
                    validator: (value) =>
                        value!.isEmpty ? "Vui lòng nhập loại sản phẩm" : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: "Giá *"),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? "Vui lòng nhập giá sản phẩm" : null,
                    onChanged: (value) {
                      setState(() {
                        // Tự động định dạng giá tiền khi nhập
                        String cleaned =
                            value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (cleaned.isNotEmpty) {
                          _priceController.text =
                              NumberFormat("#,###", "vi_VN").format(
                            int.parse(cleaned),
                          );
                          _priceController.selection =
                              TextSelection.fromPosition(
                            TextPosition(offset: _priceController.text.length),
                          );
                        }
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text("Lưu thay đổi"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
