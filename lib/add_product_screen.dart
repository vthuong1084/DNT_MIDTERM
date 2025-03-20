import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html; 

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Uint8List? _webImage;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final html.FileUploadInputElement input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      input.onChange.listen((event) {
        final file = input.files?.first;
        if (file != null) {
          final reader = html.FileReader();
          reader.readAsDataUrl(file);
          reader.onLoadEnd.listen((_) {
            setState(() {
              _webImage = Base64Decoder().convert(reader.result.toString().split(',').last);
              _base64Image = base64Encode(_webImage!);
            });
          });
        }
      });
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _base64Image = base64Encode(bytes);
        });
      }
    }
  }

  // Lưu sản phẩm vào Firestore
  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text.trim();
      String category = _categoryController.text.trim();
      num price = num.tryParse(_priceController.text) ?? 0; // Đảm bảo không bị lỗi kiểu dữ liệu

      try {
        String productId = FirebaseFirestore.instance.collection('products').doc().id;

        await FirebaseFirestore.instance.collection('products').doc(productId).set({
          'idsanpham': productId,
          'loaisp': category,
          'gia': price,
          'hinhanh': _base64Image ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Thêm sản phẩm thành công!")),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: Không thể thêm sản phẩm")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thêm sản phẩm"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                  ),
                  child: _webImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_webImage!, width: 120, height: 120, fit: BoxFit.cover),
                        )
                      : Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Tên sản phẩm *", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Vui lòng nhập tên sản phẩm" : null,
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: "Loại sản phẩm *", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Vui lòng nhập loại sản phẩm" : null,
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Giá *", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Vui lòng nhập giá sản phẩm" : null,
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveProduct,
                child: Text("Thêm mới sản phẩm"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
