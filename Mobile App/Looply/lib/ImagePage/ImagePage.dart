// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:photo_manager/photo_manager.dart';
//
// class ImagePage extends StatelessWidget {
//   const ImagePage({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             ClassificationSection(),
//             Expanded(
//               child: GridImageSection(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class ClassificationSection extends StatelessWidget {
//   const ClassificationSection({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(12),
//       child: Column(
//         children: [
//           Align(
//             alignment: Alignment.topLeft,
//             child: Text(
//               'Images',
//               style: TextStyle(
//                 fontSize: 25,
//                 color: Colors.black,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           Container(
//             height: 60,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: 20,
//               itemBuilder: (context, index) {
//                 return Container(
//                   height: 50,
//                   width: 50,
//                   margin: EdgeInsets.all(5),
//                   decoration: BoxDecoration(
//                     color: Colors.blue,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class GridImageSection extends StatefulWidget {
//   @override
//   _GridImageSectionState createState() => _GridImageSectionState();
// }
//
// class _GridImageSectionState extends State<GridImageSection> {
//   ValueNotifier<List<bool>> selectedItemsNotifier = ValueNotifier([]);
//   List<AssetEntity> images = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchImages();
//   }
//
//   Future<void> _fetchImages() async {
//     var result = await PhotoManager.requestPermissionExtend();
//     if (result.isAuth) {
//       List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
//         type: RequestType.image,
//       );
//
//       List<AssetEntity> imgList = [];
//       for (var album in albums) {
//         final int assetCount = await album.assetCountAsync;
//         if (assetCount > 0) {
//           final List<AssetEntity> assets = await album.getAssetListPaged(
//               page: 0, size: assetCount);
//           imgList.addAll(assets);
//         }
//       }
//
//       if (imgList.isNotEmpty) {
//         images = imgList;
//         selectedItemsNotifier.value = List.filled(images.length, false);
//       } else {
//         print('No images found');
//       }
//     } else {
//       // Handle the case when permission is not granted
//       print('Permission not granted');
//     }
//   }
//
//   void toggleSelectionMode(int index) {
//     if (index >= 0 && index < selectedItemsNotifier.value.length) {
//       final updatedSelections = List<bool>.from(selectedItemsNotifier.value);
//       updatedSelections[index] = !updatedSelections[index];
//       selectedItemsNotifier.value = updatedSelections;
//     } else {
//       print('Invalid index: $index');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(8.0),
//       child: images.isEmpty
//           ? Center(child: CircularProgressIndicator())
//           : ValueListenableBuilder<List<bool>>(
//         valueListenable: selectedItemsNotifier,
//         builder: (context, selectedItems, _) {
//           return GridView.builder(
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3, // Number of columns
//             ),
//             itemCount: images.length, // Number of items in the grid
//             itemBuilder: (context, index) {
//               return ImageNode(
//                 assetEntity: images[index],
//                 isSelected: selectedItems[index],
//                 onTap: () => toggleSelectionMode(index),
//                 onLongPress: () => toggleSelectionMode(index),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
//
// class ImageNode extends StatelessWidget {
//   final AssetEntity assetEntity;
//   final bool isSelected;
//   final VoidCallback onTap;
//   final VoidCallback onLongPress;
//
//   const ImageNode({
//     Key? key,
//     required this.assetEntity,
//     required this.isSelected,
//     required this.onTap,
//     required this.onLongPress,
//   }) : super(key: key);
//
//   Future<Uint8List> _getAssetData(AssetEntity assetEntity) async {
//     final data = await assetEntity.originBytes;
//     return data!;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       onLongPress: onLongPress,
//       child: AnimatedContainer(
//         padding: isSelected ? EdgeInsets.all(10) : EdgeInsets.all(0),
//         duration: Duration(milliseconds: 100),
//         margin: EdgeInsets.all(2),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.blue.shade100 : Colors.blue.shade50,
//           borderRadius: BorderRadius.circular(6),
//         ),
//         child: FutureBuilder<Uint8List>(
//           future: _getAssetData(assetEntity),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.done &&
//                 snapshot.hasData) {
//               return ImageHolder(image: snapshot.data!);
//             } else {
//               return Center(child: CircularProgressIndicator());
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
//
// class ImageHolder extends StatelessWidget {
//   final Uint8List image;
//
//   const ImageHolder({
//     Key? key,
//     required this.image,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Image.memory(
//       image,
//       fit: BoxFit.cover,
//     );
//   }
// }
