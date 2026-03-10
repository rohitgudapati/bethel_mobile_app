import 'package:bethelprayerhouse/screens/main_ui/ministriespage/childrensscreen.dart';
import 'package:flutter/material.dart';

import '../../../custom_widgets/screen_size.dart';
import '../../../custom_widgets/text_widget.dart';
import '../../../custom_widgets/top_search_widget.dart';
import '../../utils/colors.dart';

class MinistriesScreen extends StatefulWidget {
  const MinistriesScreen({super.key});

  @override
  State<MinistriesScreen> createState() => _MinistriesScreenState();
}

class _MinistriesScreenState extends State<MinistriesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: getHeight(context),
        width: getWidth(context),
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/bg.png'), fit: BoxFit.cover)),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const TopSearchWidget(show: true, backarrowshow: true),
              const SizedBox(height: 31),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 23),
                child: Column(
                  children: [
                    Row(
                      children: [
                        TextWidget(
                            text: 'Ministries',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                      ],
                    ),
                    for(int i=0; i<8; i++)
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> const ChildrensScreen()));
                      },
                      child: Container(
                          width: getWidth(context),
                          margin: const EdgeInsets.symmetric(horizontal: 17),
                          child: Column(
                            children: [
                              Container(
                                 margin: const EdgeInsets.symmetric(horizontal: 20,vertical: 30),
                                padding: const EdgeInsets.symmetric(vertical: 80),
                                width: getWidth(context),
                                decoration: BoxDecoration(
                                    image: const DecorationImage(
                                        image: AssetImage(
                                            'assets/ministriesimage.png'),
                                        fit: BoxFit.cover),
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              TextWidget(
                                  text: "Children's Ministry",
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: blackColor,
                                  fontFamily: 'Poppins'),
                            ],
                          )),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
