import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'add_product_screen.dart';
import 'update_product_screen.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Xác nhận đăng xuất"),
          content: Text("Bạn có chắc chắn muốn đăng xuất không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng hộp thoại
              },
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Đóng hộp thoại
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                } catch (e) {
                  print("Lỗi đăng xuất: $e");
                }
              },
              child: Text("Đăng xuất", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Xác nhận xóa"),
          content: Text("Bạn có chắc chắn muốn xóa sản phẩm này không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng hộp thoại
              },
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng hộp thoại
                _deleteProduct(docId); // Gọi hàm xóa sản phẩm
              },
              child: Text("Xóa", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(String docId) async {
    try {
      await _firestore.collection('products').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Xóa sản phẩm thành công!")),
      );
    } catch (e) {
      print("Lỗi khi xóa sản phẩm: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                "DANH SÁCH SẢN PHẨM",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: "Đăng xuất",
                child: IconButton(
                  icon: Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    _confirmSignOut();
                  },
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF2196F3),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddProductScreen()),
                    );
                  },
                  icon: Icon(Icons.add, size: 18),
                  label: Text("Thêm sản phẩm"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    textStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text("Không có sản phẩm nào",
                          style: TextStyle(fontSize: 16)));
                }

                final products = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final doc = products[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // Lấy giá sản phẩm
                    var price = data["gia"];
                    String priceFormatted = "Không xác định";
                    if (price != null) {
                      try {
                        double priceValue = double.parse(price.toString());
                        priceFormatted =
                            NumberFormat('#,###', 'vi_VN').format(priceValue);
                      } catch (e) {
                        print("Lỗi khi định dạng giá: $e");
                      }
                    }

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: data["hinhanh"] != null &&
                                  data["hinhanh"].isNotEmpty
                              ? Image.memory(
                                  const Base64Decoder()
                                      .convert(data["hinhanh"]),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.image, size: 50, color: Colors.grey),
                        ),
                        title: Text(
                          data["idsanpham"] ?? "Không có mã SP",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Loại: ${data["loaisp"] ?? "Không có loại"}",
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              "Giá: $priceFormatted VND",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateProductScreen(
                                      productId: doc.id,
                                      productData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
