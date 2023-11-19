import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';

class UploadPage extends StatefulWidget {
  UploadPage({Key? key}) : super(key: key);

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? responseData;
  String? filtragem;

  ImagePicker imagepicker = ImagePicker();
  List<XFile> pickedImages = [];

  // Image image = Image.asset('assets/images.png');
  Image? image;

  final dropValue = ValueNotifier('');

  final dropItems = [
    'otsu',
    'roberts_x',
    'roberts_y',
    'sobel_x',
    'sobel_y',
    'prewitt_x',
    'prewitt_y',
    'canny',
    'watershed',
  ];

  // Future<void> pickImageCamera() async {
  //   try {
  //     XFile? image = await imagepicker.pickImage(source: ImageSource.camera);
  //     if (image != null) {
  //       setState(() {
  //         pickedImages.add(image);
  //       });
  //     } else {
  //       setState(() {
  //         pickedImages = [image!];
  //       });
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  // Future<void> pickImageGaleria() async {
  //   try {
  //     List<XFile>? images = await imagepicker.pickMultiImage();
  //     if (images != null) {
  //       setState(() {
  //         pickedImages!.addAll(images);
  //       });
  //     } else {
  //       setState(() {
  //         pickedImages = images;
  //       });
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  // Future<void> removeImage({required String imagePath}) async {
  //   setState(() {
  //     pickedImages.removeWhere(
  //       (element) => element.path == imagePath,
  //     );
  //   });
  // }

  Future<void> uploadImagesFromPicker() async {
    try {
      Dio dio = Dio();

      String url =
          'fastapi-higorito.onrender.com/aplicar-filtro/${dropValue.value}/';

      List<XFile>? pickedImages = await ImagePicker().pickMultiImage();

      if (pickedImages == null || pickedImages.isEmpty) {
        print('Nenhuma imagem selecionada.');
        return;
      }

      FormData formData = FormData();

      for (XFile pickedImage in pickedImages) {
        String filePath = pickedImage.path;

        Directory appDocDir = await getApplicationDocumentsDirectory();

        String appFilePath = '${appDocDir.path}/${filePath.split('/').last}';

        await File(filePath).copy(appFilePath);

        formData.files.add(
          MapEntry(
            'file',
            await MultipartFile.fromFile(appFilePath),
          ),
        );
      }

      Response response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Response data: ${response.data}');
      print('Response status: ${response.statusCode}');
      print('Response status message: ${response.statusMessage}');

      String aux = dropValue.value;

      String imageDataString = response.data['${aux}_segmentation'];
      Uint8List imageBytes = base64.decode(imageDataString);
      image = Image.memory(
        imageBytes,
      );

      setState(() {});
    } on DioException catch (e) {
      // Tratar a resposta de erro aqui
      if (e.response != null) {
        print('Error response data: ${e.response!.data}');
      } else {
        print('Error: ${e.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Segmentação de Imagens',
              style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
          centerTitle: true,
          elevation: 2,
          backgroundColor: Colors.blueGrey,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: dropValue,
                    builder: (BuildContext context, String value, _) {
                      return DropdownButton<String>(
                        borderRadius: BorderRadius.circular(8),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black),
                        hint: const Text('Selecione o filtro'),
                        underline: Container(
                          height: 2,
                          color: Colors.black,
                        ),
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                        value: value.isNotEmpty ? value : null,
                        onChanged: (escolha) =>
                            dropValue.value = escolha.toString(),
                        items: dropItems
                            .map((op) => DropdownMenuItem(
                                  value: op,
                                  child: Text(op),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(
                    width: 18,
                  ),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     pickImageCamera();
                  //   },
                  //   child: const Text('Camera'),
                  // ),
                  // const SizedBox(
                  //   width: 10,
                  // ),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     pickImageGaleria();
                  //   },
                  //   child: const Text('Galeria'),
                  // ),
                  // const SizedBox(
                  //   width: 10,
                  // ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          backgroundColor: const Color(0xFF4CAF50),
                          // side: const BorderSide(
                          //   color: Colors.black,
                          //   width: 2,
                          // ),
                          shadowColor: Colors.cyanAccent,
                          elevation: 4,
                          minimumSize: const Size(120, 40)),
                      onPressed: () async {
                        await uploadImagesFromPicker();
                        setState(() {});
                      },
                      child: const Text(
                        'Aplicar',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.white),
                      )),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                child: image ??
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LottieBuilder.asset(
                            'assets/lottie/bichinhopulando.json'),
                        const Text('Nenhuma imagem selecionada!'),
                      ],
                    ),
              ),
            ],
          ),
        ));
  }
}
