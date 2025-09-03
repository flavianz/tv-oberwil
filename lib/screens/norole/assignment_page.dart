import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  final controller = TextEditingController();
  bool hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Mit Mitglied verknüpfen"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Mit Code", icon: Icon(Icons.pin)),
              Tab(text: "Mit QR-Code", icon: Icon(Icons.qr_code)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  spacing: 15,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Fast geschafft.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 500),
                      child: Text(
                        "Dein Konto ist noch mit keinem Mitglied verknüpft. Bitte deinen Trainer oder die Mitgliederverwaltung um einen Verknüpfungs-Code oder QR-Code",
                        maxLines: 20,
                      ),
                    ),
                    SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 500),
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: "Dein Verknüpfungs-Code",
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        FirebaseFunctions.instanceFor(region: "europe-west3")
                            .httpsCallable("assignUserToMember")
                            .call({"cipher": controller.text});
                      },
                      child: Text("Verknüpfen"),
                    ),
                  ],
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        "Fast geschafft.",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 500),
                        child: Text(
                          "Dein Konto ist noch mit keinem Mitglied verknüpft. Bitte deinen Trainer oder die Mitgliederverwaltung um einen Verknüpfungs-Code oder QR-Code",
                          maxLines: 20,
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        height: constraints.maxHeight * 0.4,
                        // 40% of available height
                        child:
                            hasScanned
                                ? CircularProgressIndicator()
                                : ExcludeSemantics(
                                  child: MobileScanner(
                                    onDetect: (result) async {
                                      if (hasScanned == false) {
                                        print(result.barcodes.first.rawValue);
                                        setState(() {
                                          hasScanned = true;
                                        });
                                        final assignmentResult =
                                            await FirebaseFunctions.instanceFor(
                                                  region: "europe-west3",
                                                )
                                                .httpsCallable(
                                                  "assignUserToMember",
                                                )
                                                .call({
                                                  "cipher":
                                                      result
                                                          .barcodes
                                                          .first
                                                          .rawValue,
                                                });
                                        if (assignmentResult.data["error"] !=
                                            false) {
                                          setState(() {
                                            hasScanned = false;
                                          });
                                        }
                                      } else {
                                        print(
                                          "skipped scan '${result.barcodes.first.rawValue}'",
                                        );
                                      }
                                    },
                                  ),
                                ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
