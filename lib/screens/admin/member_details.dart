import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tv_oberwil/components/details_edit_page.dart';
import 'package:tv_oberwil/firestore_providers/basic_providers.dart';

import '../../components/input_boxes.dart';

class MemberDetailsScreen extends StatelessWidget {
  final String uid;
  final bool created;

  const MemberDetailsScreen({
    super.key,
    required this.uid,
    this.created = false,
  });

  @override
  Widget build(BuildContext context) {
    return DetailsEditPage(
      doc: FirebaseFirestore.instance.collection("members").doc(uid),
      tabs: [
        (
          tab: null,
          type: DetailsTabType.details,
          data: [
            [
              DetailsEditProperty(
                "first",
                "Vorname",
                DetailsEditPropertyType.text,
                data: true,
              ),
              DetailsEditProperty(
                "middle",
                "2. Vorname",
                DetailsEditPropertyType.text,
              ),
              DetailsEditProperty(
                "last",
                "Nachname",
                DetailsEditPropertyType.text,
                data: true,
              ),
            ],
            [
              DetailsEditProperty(
                "birthdate",
                "Geburtstag",
                DetailsEditPropertyType.date,
              ),
              DetailsEditProperty(
                "user",
                "Verknüpft",
                DetailsEditPropertyType.custom,
                data: (
                  builder: (dynamic data, Function _) {
                    return InputBox(
                      inputWidget: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText:
                              data == null ? "Nein - Jetzt verknüpfen" : "Ja",
                          prefixIcon: Icon(Icons.link),
                        ),
                        readOnly: true,
                        onTap: () async {
                          if (data == null) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(child: UserAssignDialog(uid));
                              },
                            );
                          }
                        },
                      ),
                      title: "Verknüpft",
                    );
                  },
                  defaultValue: null,
                ),
              ),
            ],
          ],
        ),
      ],
      created: created,
      titleKey: "first",
    );
  }
}

class UserAssignDialog extends ConsumerStatefulWidget {
  final String memberId;

  const UserAssignDialog(this.memberId, {super.key});

  @override
  ConsumerState<UserAssignDialog> createState() => _UserAssignDialogState();
}

class _UserAssignDialogState extends ConsumerState<UserAssignDialog> {
  @override
  Widget build(BuildContext context) {
    final encrypted = ref.watch(
      callableProvider(
        CallableProviderArgs("getEncryptedMemberId", {"id": widget.memberId}),
      ),
    );

    if (encrypted.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (encrypted.hasError || !encrypted.hasValue) {
      return Center(child: Text("Error: ${encrypted.error}"));
    }

    final data = encrypted.value!.data;
    if (data["error"] == true) {
      return Center(child: Text(data["reason"]));
    }
    final encryptedMemberId = data["cipher"];

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 400, maxHeight: 500),
      child: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Mitglied mit Benutzer verknüpfen",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: "Mit Code", icon: Icon(Icons.pin)),
                Tab(text: "Mit QR-Code", icon: Icon(Icons.qr_code)),
              ],
            ),
            // Wrap in Flexible or SizedBox with max height
            Flexible(
              child: Padding(
                padding: EdgeInsetsGeometry.all(16),
                child: TabBarView(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Teile diesen Code mit dem Mitglied"),
                        SizedBox(height: 20),
                        Row(
                          spacing: 5,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(
                                  text: encryptedMemberId,
                                ),
                                readOnly: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                maxLines: 4,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Code kopiert!')),
                                );
                                await Clipboard.setData(
                                  ClipboardData(text: encryptedMemberId),
                                );
                              },
                              icon: Icon(Icons.copy_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Teile diesen QR-Code mit dem Mitglied"),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: QrImageView(
                            data: encryptedMemberId,
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
