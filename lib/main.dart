import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// start of the app
void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

// main screen
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // To store file path
  String? filePath;
  // A 2-D list to store the csv which is converted to List.
  List<List<dynamic>> data = [];
  // Take in user input
  TextEditingController userInputController = TextEditingController();

  // boolean for Circular Progress Inidicator
  bool isLoading = false;

// dispose controller to prevent memory leak
  @override
  void dispose() {
    userInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // There are 3 widgets in this stack, named Widget 1, 2, 3

// Widget 1
          Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    // Take in user input
                    child: TextField(
                        autofocus: true,
                        controller: userInputController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Input VCC',
                          errorText: errorText,
                        ),
                        onChanged: (_) {
                          setState(() {});
                        }),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (errorText == null) {
                        setState(() {
                          isLoading = true;
                        });
                        // get the VCCL from the internet
                        accessFile(
                          url:
                              'https://tsaenrollmentbyidemia.tsa.dhs.gov/ccl/VCCL.CSV',
                          fileName: 'VCCL.csv',
                        );
                      }
                    },
                    child: const Text('Check ID'),
                  ),
                ],
              ),
            ),
          ),
          // Widget 2
          // barrier to prevent user interaction while awaiting future/getting results
          if (isLoading)
            const Opacity(
              opacity: 0.8,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
          // widget 3
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  // Accessing the file and its contents in 3 steps stated below

  // 1 access the file on the internet
  Future accessFile({required url, String? fileName}) async {
    final file = await downloadFile(url, fileName!);
    if (file == null) {
      return;
    }

    filePath = file.path;

    _readFile(filePath);
  }

// 2 Download the file on the internet
  Future<File?> downloadFile(String url, String fileName) async {
    // save the path temporarily using dio from the internet
    // It is a future
    final appStorage = await getApplicationDocumentsDirectory();
    final file = File('${appStorage.path}/$fileName');
    // catch error while fetching document
    try {
      final response = await Dio().get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: 0,
        ),
      );
      final raf = file.openSync(mode: FileMode.write);
      raf.writeFromSync(response.data);
      await raf.close();

      return file;
    } catch (e) {
      return null;
    }
  }

// 3 After downloading and accessing the file, read the contents of the csv file and convert to List
  void _readFile(String? filePath) async {
    final input = File(filePath!).openRead();
    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();
    // Assign to the List data
    data = fields;
    // search the contents of the file
    _searchFile();
  }

// search the contents of the file for the user input
  void _searchFile() async {
    final text = userInputController.text.toString();

    // isNotValidId can be null, to catch errors
    bool? isNotValidId;
// a better method is using the contain function
// data.contain(nums)

// search for the user input
    for (var i = 0; i < data.length; i++) {
      // nums = elements of data
      String nums = data[i][0].toString();
      nums = nums.substring(1);
      // if found return true
      if (text == nums) {
        isNotValidId = true;
        break;
      }
      // else if not found at the end of the loop return false
      if (i == (data.length - 1)) {
        isNotValidId = false;
      }
    }
    setState(() {
      // After all checking process
      //Remove the circular progress indicator and rebuild the UI
      isLoading = false;
    });

    //then show dialogbox for ID status verdict
    showDialog(
        context: context,
        builder: (BuildContext context) {
          if (isNotValidId == true) {
            return const AlertDialog(
              content: Text('Invalid ID'),
            );
          } else if (isNotValidId == false) {
            return const AlertDialog(
              content: Text('Valid ID'),
            );
          } else {
            // return error if search is incomplete
            return const AlertDialog(
              content: Text('Error, search Incomplete'),
            );
          }
        });
  }

  //helper for errors gotten during input
  // if input is not 8 characters, dont enable check ID
  String? get errorText {
    final text = userInputController.value.text;
    if (text.isEmpty) {
      return 'can\'t be empty';
    }
// I could use RegExp here
// 1) Could fails some other characters on keyboard test
    if (text.contains('.') ||
        text.contains('*') ||
        text.contains('#') ||
        text.contains('#')) {
      return 'can\'t contain special characters';
    }
    if (text.length != 8) {
      return 'must be 8 digits';
    }

    return null;
  }
}
