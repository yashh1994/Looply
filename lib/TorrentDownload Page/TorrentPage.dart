import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:looply/Globals.dart';
import 'dart:convert';
import 'dart:io'; // For saving files
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Needed only for web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;


class TorrentDownloadPage extends StatefulWidget {
  final String magnet;
  const TorrentDownloadPage({required this.magnet});

  @override
  State<TorrentDownloadPage> createState() => _TorrentDownloadPageState();
}

class _TorrentDownloadPageState extends State<TorrentDownloadPage> {
  List<Map<String, dynamic>> files = [];
  Map<int, double> progress = {};
  final serverIP = "localhost";

  bool _isLoading = false;


  Future<List<Map<String, dynamic>>> getTorrentInfo(String magnet) async {
    setState(() {
      _isLoading = true;
    });
    try {
      pri("------- TORRENT INFO ---------");
      final encoded = Uri.encodeComponent(magnet);
      // final serverIP = "192.168.0.141"; // ✅ put at top of class or global
      final res = await http.get(
        Uri.parse('http://$serverIP:3000/torrent-info?magnet=magnet:?xt=urn:btih:0F61C0478326C8E2F8A397F59D7917A0DC558718&dn=Deadpool+2016+1080p+BluRay+x264+DTS-JYK&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80%2Fannounce&tr=udp%3A%2F%2Fglotorrents.pw%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.publicbt.com%3A80%2Fannounce&tr=http%3A%2F%2Fretracker.krs-ix.ru%2Fannounce&tr=http%3A%2F%2Ftracker.baravik.org%3A6970%2Fannounce&tr=http%3A%2F%2Fannounce.xxx-tracker.com%3A2710%2Fannounce&tr=http%3A%2F%2Fmgtracker.org%3A2710%2Fannounce&tr=http%3A%2F%2Ftracker1.wasabii.com.tw%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce&tr=http%3A%2F%2Ftracker.openbittorrent.com%3A80%2Fannounce&tr=udp%3A%2F%2Fopentracker.i2p.rocks%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.internetwarriors.net%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.leechers-paradise.org%3A6969%2Fannounce&tr=udp%3A%2F%2Fcoppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.zer0day.to%3A1337%2Fannounce'),
      ).timeout(Duration(seconds: 60));

      pri("Response: ${res.body}");

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        pri("------ FILES: ${json['files']} ------");

        setState(() {
          _isLoading = false;
        });

        return List<Map<String, dynamic>>.from(json['files']);
      } else {
        throw Exception("Failed to load torrent info");
      }
    } catch (er) {
      setState(() {
        _isLoading = false;
      });
      pri("Error: $er");
      return [];
    }
  }


  @override
  void initState() {
    super.initState();
    pri("ok");
    getTorrentInfo(widget.magnet).then((res) {
      setState(() => files = res);
    });
  }

  Future<void> downloadFile(int index, String name) async {
    final encodedMagnet = Uri.encodeComponent(widget.magnet);
    // final serverIP = "192.168.0.141"; // or make this configurable
    final url = 'http://$serverIP:3000/download-file?magnet=$encodedMagnet&index=$index';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = response.bodyBytes;

      if (kIsWeb) {
        // ✅ Flutter Web logic
        final blob = html.Blob([data]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", name)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // ✅ Mobile/Desktop logic
        final directory = await getApplicationDocumentsDirectory();
        final file = io.File('${directory.path}/$name');
        await file.writeAsBytes(data);
      }

      setState(() {
        progress[index] = 1.0;
      });
    } else {
      debugPrint("Failed to download file: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Torrent Files')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  final sizeMB = (file['size'] / (1024 * 1024)).toStringAsFixed(
                    2,
                  );
                  return ListTile(
                    title: Text(file['name']),
                    subtitle: Text('$sizeMB MB'),
                    trailing:
                        progress[index] == null
                            ? IconButton(
                              icon: Icon(Icons.download),
                              onPressed:
                                  () => downloadFile(index, file['name']),
                            )
                            : SizedBox(
                              width: 100,
                              child: LinearProgressIndicator(
                                value: progress[index],
                              ),
                            ),
                  );
                },
              ),
    );
  }
}
