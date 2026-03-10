import 'package:flutter/material.dart';

import '../../../custom_widgets/screen_size.dart';
import '../../../custom_widgets/text_widget.dart';
import '../../../custom_widgets/top_search_widget.dart';
import '../../utils/colors.dart';

class ChildrensScreen extends StatefulWidget {
  const ChildrensScreen({super.key});

  @override
  State<ChildrensScreen> createState() => _ChildrensScreenState();
}

class _ChildrensScreenState extends State<ChildrensScreen> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Container(
         height: getHeight(context),
        width: getWidth(context),
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/bg.png'), fit: BoxFit.cover)),
                child:  Column(children: [
                   const TopSearchWidget(show: true, backarrowshow: true),
                   const SizedBox(height: 31),
                   Container(
                    margin: const EdgeInsets.symmetric(horizontal: 23),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                            text: "Children's Ministry",
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                            fontFamily: 'Poppins'),
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
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 23),
                                child: TextWidget(
                                    text: 'Lorem Ipsum is simply dummy text of the printing and type setting industry. Lorem Ipsum has been the simplindustrys standard dummy.',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: blackColor,
                                    fontFamily: 'Poppins'),
                              ),
                      ],
                    ),
                   )
                ],)
      ),
    );
  }
}