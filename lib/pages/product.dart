import 'package:flutter/material.dart';
import '../database/model.dart';
import '../database/database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // เพิ่ม table_calendar

class ProductListScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const ProductListScreen({Key? key, required this.dbHelper}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> products = [];

  // Confirm dialog for deletion
  Future<bool?> _showConfirmDialog(BuildContext context, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean-UP application'),
      ),
      body: Stack(
        // ใช้ Stack ในการซ้อนวัตถุ
        children: [
          Container(
            color: Colors.orange[100], // พื้นหลังสีส้มอ่อน
            child: Column(
              children: [
                // ส่วนของโฆษณา
                Container(
                  height: 400, // ปรับความสูงของกรอบให้ใหญ่ขึ้น
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5, // จำนวนโฆษณาที่จะแสดง (เพราะมี 5 รูป)
                    itemBuilder: (context, index) {
                      String imagePath = 'assets/images/maaban${index + 1}.png';

                      return Container(
                        width: 300, // ปรับความกว้างของกรอบให้ใหญ่ขึ้น
                        margin: EdgeInsets.all(16.0), // เพิ่ม margin รอบๆ กรอบ
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              16.0), // เพิ่มความโค้งให้กรอบ
                          gradient: LinearGradient(
                            colors: [Colors.orange[300]!, Colors.orange[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ), // เพิ่ม gradient ที่ทำให้ดูสวยงามมากขึ้น
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.2), // เงาสีดำอ่อน
                              blurRadius: 8, // ความเบลอของเงา
                              offset: Offset(4, 4), // ทิศทางของเงา
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              16.0), // ให้รูปภาพมีมุมโค้งเหมือนกับกรอบ
                          child: Column(
                            children: [
                              Expanded(
                                flex:
                                    4, // ใช้ flex เพื่อเพิ่มพื้นที่ให้กับรูปภาพ
                                child: Image.asset(
                                  imagePath, // แสดงรูปภาพจาก assets
                                  fit: BoxFit
                                      .cover, // จัดการให้รูปภาพครอบคลุมพื้นที่
                                ),
                              ),
                              SizedBox(
                                  height:
                                      10), // เพิ่มพื้นที่ระหว่างรูปภาพกับข้อความ
                              Expanded(
                                flex: 1, // พื้นที่สำหรับข้อความโฆษณา
                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    'เเม่บ้านทำความสะอาดหมายเลขที่ ${index + 1}', // ข้อความโฆษณา
                                    textAlign: TextAlign
                                        .center, // จัดให้ข้อความอยู่กลาง
                                    style: TextStyle(
                                      color: Colors.white, // เปลี่ยนสีตัวอักษร
                                      fontSize: 18, // ขนาดฟอนต์
                                      fontWeight:
                                          FontWeight.bold, // ทำให้ตัวหนา
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ส่วนของข้อมูล
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: widget.dbHelper.getStream(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      products.clear();
                      for (var element in snapshot.data!.docs) {
                        var data = element.data() as Map<String, dynamic>;
                        products.add(Product(
                          name: element.get('name'),
                          description: element.get('description'),
                          favorite: element.get('favorite'),
                          referenceId: element.id,
                          contactnumber: data.containsKey('contactnumber')
                              ? data['contactnumber']
                              : '',
                          address: data.containsKey('address')
                              ? data['address']
                              : '',
                          bookingTime: data.containsKey('bookingTime')
                              ? data['bookingTime']
                              : '',
                        ));
                      }

                      return ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return Dismissible(
                            key: UniqueKey(),
                            background: Container(color: Colors.blue),
                            secondaryBackground: Container(
                              color: Colors.red,
                              child: const Icon(Icons.delete),
                              alignment: Alignment.centerRight,
                            ),
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                // ลบข้อมูลจาก SQLite
                                widget.dbHelper.deleteProduct(products[index]);

                                // ลบข้อมูลจาก Firestore
                                FirebaseFirestore.instance
                                    .collection('bookings')
                                    .where('name',
                                        isEqualTo: products[index].name)
                                    .get()
                                    .then((snapshot) {
                                  for (DocumentSnapshot ds in snapshot.docs) {
                                    ds.reference.delete();
                                  }
                                });

                                // อัพเดตหน้าจอหลังจากลบข้อมูล
                                setState(() {
                                  products.removeAt(index);
                                });
                              }
                            },
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                return await _showConfirmDialog(
                                    context, 'แน่ใจว่าจะลบการจองนี้?');
                              }
                              return false;
                            },
                            child: Card(
                              elevation: 5,
                              margin: const EdgeInsets.all(8.0),
                              child: ListTile(
                                title: Text(products[index].name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'เลือกเเม่บ้านคนไหน: ${products[index].description}'),
                                    Text(
                                        'เบอร์: ${products[index].contactnumber}'),
                                    Text('ที่อยู่: ${products[index].address}'),
                                    // แก้ไขการแสดงเวลาจอง
                                    Text(
                                        'เวลาจอง: ${products[index].bookingTime is Timestamp ? DateFormat('dd/MM/yyyy HH:mm').format((products[index].bookingTime as Timestamp).toDate()) : products[index].bookingTime}'),
                                  ],
                                ),
                                onTap: () async {
                                  var result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailScreen(
                                          productdetail: products[index]),
                                    ),
                                  );
                                  setState(() {
                                    if (result != null) {
                                      products[index].favorite = result;
                                      widget.dbHelper
                                          .updateProduct(products[index]);
                                    }
                                  });
                                },
                                onLongPress: () async {
                                  await ModalEditProductForm(
                                    dbHelper: widget.dbHelper,
                                    editedProduct: products[index],
                                  ).showModalInputForm(context);
                                },
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
          ),

          // วางปุ่ม + ด้านบนปุ่มลูกศร
          Positioned(
            bottom: 90, // ย้ายปุ่ม + ขึ้นไปเล็กน้อย
            right: 20, // ระยะจากขอบขวาของหน้าจอ
            child: FloatingActionButton(
              onPressed: () async {
                await ModalProductForm(dbHelper: widget.dbHelper)
                    .showModalInputForm(context);
              },
              child: const Icon(Icons.add),
              backgroundColor: Colors.orange,
            ),
          ),

          // วางปุ่มลูกศรด้านล่างปุ่ม +
          Positioned(
            bottom: 20, // ระยะจากล่างสุดของหน้าจอ
            right: 20, // ระยะจากขอบขวาของหน้าจอให้ตรงกับปุ่ม +
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SecondPage()), // นำทางไปหน้าใหม่
                );
              },
              child: const Icon(Icons.arrow_forward), // ไอคอนสำหรับปุ่มลูกศร
              backgroundColor: Colors.orange, // สีปุ่มเป็นสีส้ม
            ),
          ),
        ],
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({Key? key, required this.productdetail}) : super(key: key);

  final Product productdetail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(productdetail.name),
        backgroundColor: Colors.orange, // เปลี่ยนสี AppBar เป็นสีส้ม
      ),
      body: Container(
        height: double.infinity, // เพิ่มให้ความสูงครอบคลุมทั้งหน้า
        decoration: BoxDecoration(
          color: Colors.orange[50], // เปลี่ยนสีพื้นหลังเป็นสีส้มจาง
        ),
        child: Padding(
          padding: const EdgeInsets.all(20), // เพิ่ม Padding รอบ ๆ
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ชื่อผู้จองเเละรายละเอียด: ${productdetail.name}',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Divider(),
                              Text(
                                'เเม่บ้านที่เลือก: ${productdetail.description}',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Divider(),
                              Text(
                                'ที่อยู่: ${productdetail.address}',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Divider(),
                              Text(
                                'เบอร์โทร: ${productdetail.contactnumber}',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Divider(),
                              Text(
                                'เวลาการจอง: ${productdetail.bookingTime}',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(), // เพิ่มเพื่อให้ปุ่มอยู่ด้านล่าง
              Center(
                child: ElevatedButton(
                  child: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.orange,
                    fixedSize: const Size(120, 40),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModalProductForm {
  ModalProductForm({Key? key, required this.dbHelper});
  final DatabaseHelper dbHelper;

  String _name = '', _description = '';
  String _address = '';
  String _contactnumber = '';
  final int _favorite = 0;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      _selectedTime = picked;
    }
  }

  Future<void> showModalInputForm(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFFCC80), // สีพื้นหลังของโมดัลเป็นสีส้มจาง
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // ขอบมุมที่โค้งมน
          ),
          title: const Text(
            'เพิ่มการจอง',
            style: TextStyle(color: Colors.black), // ตัวอักษรเป็นสีดำ
          ),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'ชื่อ เเละ รายละเอียด',
                      labelStyle: TextStyle(
                          color: Colors.black), // เปลี่ยนสีข้อความเป็นดำ
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10), // ขอบมุมที่โค้งมน
                        borderSide: BorderSide(
                            color: Colors.orangeAccent, width: 2), // ขอบสีดำ
                      ),
                      filled: true, // ตั้งค่าให้มีสีพื้นหลัง
                      fillColor: Color(0xFFFFE0B2), // สีพื้นหลังของ TextField
                    ),
                    style: TextStyle(color: Colors.black), // ตัวอักษรเป็นสีดำ
                    onChanged: (value) {
                      _name = value;
                    },
                  ),
                  SizedBox(height: 10), // เพิ่มระยะห่าง
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'เลือกเเม่บ้าน',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.orangeAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: Color(0xFFFFE0B2),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (value) {
                      _description = value;
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'เบอร์โทร',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.orangeAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: Color(0xFFFFE0B2),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (value) {
                      _contactnumber = value;
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'ที่อยู่',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.orangeAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: Color(0xFFFFE0B2),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (value) {
                      _address = value;
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => _selectDate(context),
                          child: Text(
                            _selectedDate == null
                                ? 'เลือกวันที่'
                                : 'วันที่: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                            style: TextStyle(
                                color: Colors.black), // เปลี่ยนสีข้อความเป็นดำ
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => _selectTime(context),
                          child: Text(
                            _selectedTime == null
                                ? 'เลือกเวลา'
                                : 'เวลา: ${_selectedTime!.format(context)}',
                            style: TextStyle(
                                color: Colors.black), // เปลี่ยนสีข้อความเป็นดำ
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.black), // เปลี่ยนสีปุ่มเป็นดำ
              ),
            ),
            TextButton(
              onPressed: () {
                if (_name.isNotEmpty && _description.isNotEmpty) {
                  dbHelper.insertProduct(Product(
                    name: _name,
                    description: _description,
                    favorite: _favorite,
                    contactnumber: _contactnumber,
                    address: _address,
                    bookingTime:
                        '${DateFormat('dd/MM/yyyy').format(_selectedDate!)} ${_selectedTime!.format(context)}',
                  ));

                  // บันทึกข้อมูลการจองไปยัง Firestore
                  FirebaseFirestore.instance.collection('bookings').add({
                    'name': _name,
                    'description': _description,
                    'address': _address, // เพิ่มที่อยู่
                    'contactnumber': _contactnumber, // เพิ่มเบอร์โทร
                    'bookingTime': Timestamp.fromDate(DateTime(
                        _selectedDate!.year,
                        _selectedDate!.month,
                        _selectedDate!.day)),
                  });

                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'บันทึก',
                style: TextStyle(color: Colors.black), // เปลี่ยนสีปุ่มเป็นดำ
              ),
            ),
          ],
        );
      },
    );
  }
}

class ModalEditProductForm {
  const ModalEditProductForm(
      {Key? key, required this.dbHelper, required this.editedProduct});

  final DatabaseHelper dbHelper;
  final Product editedProduct;

  Future<dynamic> showModalInputForm(BuildContext context) {
    return showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0), // เพิ่มขอบมุมที่โค้งมน
      ),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: 500,
          decoration: BoxDecoration(
            color: Color(0xFFFFCC80), // เปลี่ยนสีพื้นหลังเป็นสีส้มจาง
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(20.0)), // รักษาขอบมุมที่โค้งมนด้านบน
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: IconButton(
                  icon: Icon(Icons.close,
                      color:
                          Color.fromARGB(255, 0, 0, 0)), // เปลี่ยนสีไอคอนเป็นดำ
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: const Center(
                  child: Text(
                    'แก้ไขข้อมูล',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // เปลี่ยนสีตัวอักษรเป็นดำ
                    ),
                  ),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await dbHelper.updateProduct(editedProduct);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'บันทึก',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16), // เปลี่ยนสีตัวอักษรเป็นดำ
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: (value) {
                        editedProduct.name = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'ชื่อเเละบริการ (เช่น ทำความสะอาด)',
                        labelText: 'ชื่อเเละรายละเอียด',
                        labelStyle: TextStyle(
                            color: Colors.black), // เปลี่ยนสี label เป็นดำ
                        hintStyle: TextStyle(
                            color: Colors.black54), // เปลี่ยนสี hint เป็นดำจาง
                        filled: true, // ทำให้ TextField มีพื้นหลัง
                        fillColor: Color(0xFFFFE0B2), // สีพื้นหลังของ TextField
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.orangeAccent,
                              width: 2), // ขอบของ TextField เป็นดำ
                          borderRadius:
                              BorderRadius.circular(10), // ขอบมุมที่โค้งมน
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.orangeAccent,
                              width: 2), // ขอบเมื่อถูกเลือก
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(color: Colors.black), // ตัวอักษรเป็นสีดำ
                    ),
                    SizedBox(height: 15), // เพิ่มระยะห่างระหว่าง TextField
                    TextField(
                      onChanged: (value) {
                        editedProduct.description = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'เลือกเเม่บ้าน (เช่น แม่บ้านคนไหน)',
                        labelText: 'เลือกเเม่บ้าน',
                        labelStyle: TextStyle(color: Colors.black),
                        hintStyle: TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Color(0xFFFFE0B2),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.orangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.orangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      onChanged: (value) {
                        editedProduct.address = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'ที่อยู่',
                        labelText: 'ที่อยู่',
                        labelStyle: TextStyle(color: Colors.black),
                        hintStyle: TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Color(0xFFFFE0B2),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.orangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.orangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      onChanged: (value) {
                        editedProduct.contactnumber = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'เบอร์โทรศัพท์',
                        labelText: 'เบอร์โทรศัพท์',
                        labelStyle: TextStyle(color: Colors.black),
                        hintStyle: TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Color(0xFFFFE0B2),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.orangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.orangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  Map<DateTime, List<Map<String, dynamic>>> _bookings = {}; // ข้อมูลการจอง

  @override
  void initState() {
    super.initState();
    _fetchBookings(); // ดึงข้อมูลการจองจาก Firestore
  }

  // ฟังก์ชันดึงข้อมูลการจองจาก Firestore
  void _fetchBookings() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('bookings').get();
    Map<DateTime, List<Map<String, dynamic>>> bookings = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime bookingDate = (data['bookingTime'] as Timestamp).toDate();

      DateTime day =
          DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

      if (bookings[day] == null) {
        bookings[day] = [];
      }

      bookings[day]!.add({
        'name': data['name'],
        'description': data['description'],
        'address': data['address'],
        'contactnumber': data['contactnumber'],
        'bookingTime': data['bookingTime'] != null
            ? DateFormat('dd/MM/yyyy HH:mm')
                .format((data['bookingTime'] as Timestamp).toDate())
            : 'ไม่มีข้อมูลเวลา', // ตรวจสอบว่าข้อมูลเวลามีหรือไม่
      });
    }

    setState(() {
      _bookings = bookings;
      print('Bookings loaded: $_bookings');
    });
  }

  // ฟังก์ชันสำหรับแสดงว่ามีการจองในวันไหนบ้าง
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _bookings[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ดูวันว่าง'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay, // ฟังก์ชันโหลดเหตุการณ์ของแต่ละวัน
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red, // สีแดงสำหรับวันที่มีการจอง
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _buildBookingList(), // แสดงรายการการจองในวันที่เลือก
          ),
        ],
      ),
    );
  }

  // สร้างรายการแสดงชื่อคนจองในวันที่เลือก
  Widget _buildBookingList() {
    List<Map<String, dynamic>> events = _getEventsForDay(_selectedDay);

    if (events.isEmpty) {
      return Center(
        child: Text('วันว่าง ไม่มีการจอง'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        var event = events[index];
        return Card(
          elevation: 4, // เพิ่มเงาให้กับ Card
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // มุมโค้งมนให้กับ Card
          ),
          margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Padding(
            padding: EdgeInsets.all(16.0), // เพิ่ม padding ให้กับเนื้อหาใน Card
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ชื่อ: ${event['name']}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold, // เน้นชื่อเป็นตัวหนา
                    color: Colors.black87,
                  ),
                ),
                Divider(), // เส้นคั่นระหว่างข้อมูลแต่ละส่วน
                Row(
                  children: [
                    Icon(Icons.cleaning_services, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'แม่บ้านที่เลือก: ${event['description']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800], // สีเทาเข้ม
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4), // เพิ่มระยะห่างระหว่างบรรทัด
                Row(
                  children: [
                    Icon(Icons.home, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'ที่อยู่: ${event['address'] ?? 'ไม่มีข้อมูล'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'เบอร์โทร: ${event['contactnumber'] ?? 'ไม่มีข้อมูล'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Divider(),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text(
                      () {
                        DateTime bookingTime = DateFormat('dd/MM/yyyy HH:mm')
                            .parse(event['bookingTime']);
                        int differenceInDays =
                            bookingTime.difference(DateTime.now()).inDays;

                        if (differenceInDays > 0) {
                          return 'ใกล้ถึงเวลาในอีก $differenceInDays วัน';
                        } else if (differenceInDays == 0) {
                          return 'ใกล้ถึงเวลาแล้ว (วันนี้)';
                        } else {
                          return 'เวลาการจอง: ${event['bookingTime']}';
                        }
                      }(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
