import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photodiary/auth_page.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_core/firebase_core.dart';
import 'package:photodiary/firestore_database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '4-photo Diary',
      theme: ThemeData(
        useMaterial3: false,
      ),
      home: const AuthPage(), // 이 부분을 바꿔줘야 함.

      routes: {
        '/main': (context) => const MainScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/write') {
          final DiaryModel? diaryModel = settings.arguments as DiaryModel?;

          return MaterialPageRoute(builder: (context) {
            return WriteScreen(
              diaryModel: diaryModel,
            );
          });
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Future<List<DiaryModel>> diaryList;

  // 현재 로그인한 사용자 가져오기
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    diaryList = setDiaryData();
  }

  // Firestore를 통해 다이어리 데이터 가져오기
  Future<List<DiaryModel>> setDiaryData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // 사용자가 아직 null이면 빈 리스트를 반환하거나, 재시도 로직을 추가합니다.
      return [];
    }
    String userId = currentUser.uid;
    return FirestoreDatabaseHelper().getAllDiaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '4-Photo Diary',
          style: GoogleFonts.kaushanScript(
            textStyle: const TextStyle(fontSize: 18, color: Colors.black),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Welcome! ${user?.email ?? ''}',
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xffE3EDAF),
        child: FutureBuilder(
          future: diaryList,
          builder: (context, snapshot) {
            // 애러일 경우 에러 메시지 출력
            if (snapshot.hasError) {
              print('Error: ${snapshot.error}');

              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              );
            }

            if (snapshot.hasData) {
              return snapshot.data!.isEmpty
                  ? Center(
                      child: Text(
                        'Write first Diary',
                        style: GoogleFonts.kaushanScript(
                          textStyle:
                              const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        DiaryModel diaryModel = snapshot.data![index];

                        // 다이어리 항목 UI (기존 코드와 동일)
                        return Container(
                          margin: const EdgeInsets.only(top: 24),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: double.maxFinite,
                                height: MediaQuery.of(context).size.width,
                                child: GridView(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    Image.memory(diaryModel.imgTopLeft,
                                        fit: BoxFit.cover),
                                    Image.memory(diaryModel.imgTopRight,
                                        fit: BoxFit.cover),
                                    Image.memory(diaryModel.imgBtmLeft,
                                        fit: BoxFit.cover),
                                    Image.memory(diaryModel.imgBtmRight,
                                        fit: BoxFit.cover),
                                  ],
                                ),
                              ),

                              // title circle
                              // 원형 영역과 title을 GestureDetector로 감싸기
                              GestureDetector(
                                onTap: () {
                                  if (diaryModel.content.isNotEmpty) {
                                    contentDialog(context, diaryModel);
                                  }
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Transform.rotate(
                                      angle: 60 * math.pi / 180,
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                4,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          color: Color.fromRGBO(0, 0, 0, 0.5),
                                          borderRadius: const BorderRadius.all(
                                            Radius.elliptical(78, 85),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 원래 화면에 보이던 title 텍스트
                                    Text(
                                      diaryModel.title,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.kaushanScript(
                                        textStyle: TextStyle(
                                            fontSize: 18,
                                            color: diaryModel.content.isNotEmpty
                                                ? Colors.yellow
                                                : Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Display Date Box
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(0, 0, 0, 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(6),
                                    child: Text(
                                      DateFormat('yyyy.MM.dd').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            diaryModel.date),
                                      ),
                                      style: GoogleFonts.kaushanScript(
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // edit & delete button (top, right)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: PopupMenuButton<String>(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(0, 0, 0, 0.5),
                                    ),
                                    child: const Icon(Icons.more_vert,
                                        size: 24, color: Colors.white),
                                  ),
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      child: const Text('Modify'),
                                      onTap: () async {
                                        var result = await Navigator.of(context)
                                            .pushNamed(
                                          '/write',
                                          arguments: diaryModel,
                                        );
                                        if (result != null) {
                                          updateData(result);
                                        }
                                      },
                                    ),
                                    PopupMenuItem<String>(
                                      child: const Text('Delete'),
                                      onTap: () async {
                                        // Firestore 기반 삭제
                                        await FirestoreDatabaseHelper()
                                            .deleteDiary(diaryModel.id!);
                                        final snackbar = const SnackBar(
                                          content:
                                              Text('Delete Diary Complete'),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(snackbar);
                                        diaryList = setDiaryData();
                                        setState(() {});
                                      },
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
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () async {
          var result = await Navigator.of(context).pushNamed('/write');
          if (result != null) {
            updateData(result);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // pop-up Dialog
  void contentDialog(BuildContext context, DiaryModel diaryModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(diaryModel.title),
          content: Text(diaryModel.content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void updateData(var result) {
    if (result == "COMPLTED_UPDATE") {
      diaryList = setDiaryData();
      setState(() {});
    }
  }
}

class WriteScreen extends StatefulWidget {
  final DiaryModel? diaryModel; // null 을 허용한것은 처음 작성하기일 경우를 위함이다

  const WriteScreen({
    super.key,
    this.diaryModel,
  });

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  late ValueNotifier<dynamic> selectedImgTopLeft;
  late ValueNotifier<dynamic> selectedImgTopRight;
  late ValueNotifier<dynamic> selectedImgBtmLeft;
  late ValueNotifier<dynamic> selectedImgBtmRight;

  late bool isEdit = false; // 수정하기 모드인지 체크하는 함수

  TextEditingController inputTitleController = TextEditingController();
  TextEditingController inputContentController =
      TextEditingController(); // content용 컨트롤러

  final formKey = GlobalKey<FormState>(); // For input field validation

  int selectedDate = 0; // 선택된 날짜

  @override
  void initState() {
    // TODO: implement initState

    // 수정하기 모으일 경우
    isEdit = widget.diaryModel == null ? false : true;

    if (isEdit) {
      inputTitleController.text = widget.diaryModel!.title;
      inputContentController.text = widget.diaryModel!.content; // 기존 내용 불러오기

      selectedDate = widget.diaryModel!.date;
      selectedImgTopLeft = ValueNotifier(widget.diaryModel!.imgTopLeft);
      selectedImgTopRight = ValueNotifier(widget.diaryModel!.imgTopRight);
      selectedImgBtmLeft = ValueNotifier(widget.diaryModel!.imgBtmLeft);
      selectedImgBtmRight = ValueNotifier(widget.diaryModel!.imgBtmRight);
    } else {
      selectedImgTopLeft = ValueNotifier(null);
      selectedImgTopRight = ValueNotifier(null);
      selectedImgBtmLeft = ValueNotifier(null);
      selectedImgBtmRight = ValueNotifier(null);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? 'Modify diary'
              : // 수정하기
              'Write diary', // 작성하기
          style: GoogleFonts.kaushanScript(
            // 수정된 부분
            textStyle: TextStyle(
              color: Colors.black,
              fontSize: 18,
            ),
          ),
        ),
        leading: GestureDetector(
          child: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image select widget
            Container(
              margin: EdgeInsets.all(8),
              width: double.maxFinite,
              height: MediaQuery.of(context).size.width,
              child: GridView(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // picrute upload 4 button - 4개의 사진 업로드 버튼
                  SelectImg(
                    selectedImg: selectedImgTopLeft,
                  ),
                  SelectImg(
                    selectedImg: selectedImgTopRight,
                  ),
                  SelectImg(
                    selectedImg: selectedImgBtmLeft,
                  ),
                  SelectImg(
                    selectedImg: selectedImgBtmRight,
                  ),
                ],
              ),
            ),

            // Text input widget
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Text(
                'One-line diary',
                style: GoogleFonts.kaushanScript(
                    textStyle: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                )),
              ),
            ),

            // Input text field
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Form(
                // to check validate input sentence
                key: formKey,
                child: TextFormField(
                  validator: (val) => titleValidator(val),
                  decoration: InputDecoration(
                    hintText: 'Write simple sentence (max 20)',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xffE1E1E1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.black,
                      ),
                    ),
                  ),
                  maxLength: 20,
                  maxLines: null, // Allow multiple lines of input
                  controller: inputTitleController, // indicate Controller
                  keyboardType: TextInputType.multiline, // 여러 줄 입력 허용
                ),
              ),
            ),

            // content 입력 필드 추가
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Content(Optional)',
                style: GoogleFonts.kaushanScript(
                    textStyle: TextStyle(fontSize: 18, color: Colors.black)),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter content for diary',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xffE1E1E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                maxLines: null,
                controller: inputContentController,
                keyboardType: TextInputType.multiline,
              ),
            ),

            // Select Date
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Text(
                'Date',
                style: GoogleFonts.kaushanScript(
                  textStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            // Select Date button
            GestureDetector(
              onTap: () => _selectedDate(context),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                width: double.maxFinite,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color(0xffE1E1E1),
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.only(
                    left: 8,
                  ),

                  // 삼항 연산자를 통한 날자 입력
                  child: selectedDate == 0
                      ? Text(
                          "Select the date",
                        )
                      : Text(
                          DateFormat('yyyy.MM.dd').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  selectedDate)),
                          style: GoogleFonts.kaushanScript(
                              textStyle:
                                  TextStyle(fontSize: 16, color: Colors.black)),
                        ),
                ),
              ),
            ),

            // Confirm 버튼을 추가한다
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              width: double.maxFinite,
              child: ElevatedButton(
                onPressed: () => validateInput(),
                child: Text(
                  isEdit ? 'Modify' : 'Confirm',
                  style: GoogleFonts.kanit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future _selectedDate(BuildContext context) async {
    // 날짜를 선택하는 함수
    final DateTime? selected = await showDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDate: DateTime.now());

    if (selected != null) {
      selectedDate = selected.millisecondsSinceEpoch;
      setState(() {});
    }
  }

  // Validate Title
  dynamic titleValidator(val) {
    if (val.isEmpty) {
      return 'Write the title';
    }

    return null;
  }

  // Validate Input - image and date
  void validateInput() {
    if (formKey.currentState!.validate() &&
        isImgFieldValidate() &&
        isDateValidate()) {
      // 모두 입력이 되면 수정인 경우 수정한수 호출, 저장인 경우 저장함수 호출
      isEdit ? editData() : saveData();
    }
  }

// 흰색 이미지를 PNG 형식으로 바이트 배열로 변환하는 함수
  Future<Uint8List> _getWhiteImage(int width, int height) async {
    // Create a blank image
    img.Image whiteImage = img.Image(width: width, height: height);

    // Fill the image with white color
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Use ARGB format (A=255, R=255, G=255, B=255 for white)
        whiteImage.setPixelRgb(x, y, 255, 255, 255);
      }
    }

    // Encode the image to PNG format and return as Uint8List
    return Uint8List.fromList(img.encodePng(whiteImage));
  }

// 저장 예시 (WriteScreen 내부의 saveData 함수)
  void saveData() async {
    int imageWidth = 10;
    int imageHeight = 10;

    // Check if images are null or empty, and use a white image if so
    Uint8List imgTopLeftBytes = selectedImgTopLeft.value == null
        ? await _getWhiteImage(imageWidth, imageHeight)
        : await selectedImgTopLeft.value!.readAsBytes();

    Uint8List imgTopRightBytes = selectedImgTopRight.value == null
        ? await _getWhiteImage(imageWidth, imageHeight)
        : await selectedImgTopRight.value!.readAsBytes();

    Uint8List imgBtmLeftBytes = selectedImgBtmLeft.value == null
        ? await _getWhiteImage(imageWidth, imageHeight)
        : await selectedImgBtmLeft.value!.readAsBytes();

    Uint8List imgBtmRightBytes = selectedImgBtmRight.value == null
        ? await _getWhiteImage(imageWidth, imageHeight)
        : await selectedImgBtmRight.value!.readAsBytes();

    DiaryModel diaryModel = DiaryModel(
      title: inputTitleController.text,
      content: inputContentController.text, // content 포함

      imgTopLeft: imgTopLeftBytes,
      imgTopRight: imgTopRightBytes,
      imgBtmLeft: imgBtmLeftBytes,
      imgBtmRight: imgBtmRightBytes,
      date: selectedDate,
    );

    await FirestoreDatabaseHelper().insertDiary(diaryModel);

    final snackbar = const SnackBar(
      content: Text('Insert Diary Complete'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);

    Navigator.pop(context, "COMPLTED_UPDATE");
  }

  // 현재 이미지의 경우 보여주는 방식이 두가지 이다.
  // MainScreen : Image.memory 위젯을 사용(DB에서 바이트형태로 저장된 이미지)
  // WriteScreen : Image.file 위젯을 사용하여 보여주는 방식
  // image.memory 에서 보여주는 bytes 형태, 이미지 FILE 형태
  // 데이터를 수정하여 저장할때 모든 데이터를 Uint8List 타입으로 변환한다.
  Future<Uint8List> makeReadAsBytes(dynamic target) async {
    try {
      return await target.readAsBytes();
    } catch (e) {
      return target;
    }
  }

// 수정 예시 (WriteScreen 내부의 editData 함수)
  void editData() async {
    DiaryModel diaryModel = DiaryModel(
      id: widget.diaryModel!.id,
      title: inputTitleController.text,
      content: inputContentController.text, // 수정 시에도 반영

      imgTopLeft: await makeReadAsBytes(selectedImgTopLeft.value),
      imgTopRight: await makeReadAsBytes(selectedImgTopRight.value),
      imgBtmLeft: await makeReadAsBytes(selectedImgBtmLeft.value),
      imgBtmRight: await makeReadAsBytes(selectedImgBtmRight.value),
      date: selectedDate,
    );

    await FirestoreDatabaseHelper().updateDiary(diaryModel);

    final snackbar = const SnackBar(
      content: Text('Modify Diary Complete'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);

    Navigator.pop(context, "COMPLTED_UPDATE");
  }

  // // 기존 sqflite의 edit()메서드
  // // Modify diary data
  // void editData() async {
  //   DiaryModel diaryModel = DiaryModel(
  //     id: widget.diaryModel!.id,
  //     title: inputTitleController.text,
  //     imgTopLeft: await makeReadAsBytes(selectedImgTopLeft.value),
  //     imgTopRight: await makeReadAsBytes(selectedImgTopRight.value),
  //     imgBtmLeft: await makeReadAsBytes(selectedImgBtmLeft.value),
  //     imgBtmRight: await makeReadAsBytes(selectedImgBtmRight.value),
  //     date: selectedDate,
  //   );
  //
  //   await DatabaseHelper().initDatabase();
  //   await DatabaseHelper().updateInfo(diaryModel); // update
  //
  //   // show the insert complete message
  //   final snackbar = SnackBar(
  //     content: Text('Modify Diary Complete'),
  //   );
  //
  //   ScaffoldMessenger.of(context).showSnackBar(snackbar);
  //
  //   Navigator.pop(context, "COMPLTED_UPDATE"); // send update signal to .
  // }

  // to check at least one image be selected
  bool isImgFieldValidate() {
    bool isImgSelected = selectedImgTopLeft.value == null &&
        selectedImgTopRight.value == null &&
        selectedImgBtmLeft.value == null &&
        selectedImgBtmRight.value == null;

    if (!isImgSelected) {
      return true;
    } else {
      // 이미지가 모두 선택되지 않았다는 메시지를 띄워 준다.
      final snackbar = SnackBar(
        content: Text('Select at least one Image'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackbar);

      return false;
    }
  }

  // Check if the date is selected
  bool isDateValidate() {
    bool isDateValidate = selectedDate != 0; // 초기화 숫자가 0임

    if (isDateValidate) {
      return true;
    } else {
      final snackbar = SnackBar(
        content: Text('Choose the date'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackbar);

      return false;
    }
  }
}

//
// process a single image
//
class SelectImg extends StatefulWidget {
  final ValueNotifier<dynamic>? selectedImg; // 갤러리에서 선택한 이미지

  const SelectImg({
    super.key,
    this.selectedImg,
  });

  @override
  State<SelectImg> createState() => _selectImgState();
}

class _selectImgState extends State<SelectImg> {
  bool isNewSelected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: const Color(0xffF4F4F4),
        ),

        // show image Icon or image
        child: widget.selectedImg?.value == null
            // There is no selected image
            ? const Icon(
                Icons.image,
                color: Color(0xff868686),
              )
            // This is selected image
            : Container(
                height: MediaQuery.of(context).size.width,
                child: isNewSelected
                    ? Image.file(widget.selectedImg!.value, fit: BoxFit.cover)
                    : Image.memory(widget.selectedImg!.value,
                        fit: BoxFit.cover),
              ),
      ),
      onTap: () => getGalleryImage(),
    );
  }

  void getGalleryImage() async {
    // get through the imahe from gallery
    var image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 10,
    );

    if (image != null) {
      // If the image is selected
      widget.selectedImg?.value = File(image.path);
      isNewSelected = true; // indicate the image is selected

      setState(() {});
    }
  }
}
