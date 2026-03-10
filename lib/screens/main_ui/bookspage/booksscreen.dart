import 'package:flutter/material.dart';

import '../../../custom_widgets/screen_size.dart';
import '../../../custom_widgets/text_widget.dart';
import '../../../custom_widgets/top_search_widget.dart';
import '../../utils/colors.dart';
import '../videospage/videos.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
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
                            text: 'Shorts',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        TextWidget(
                            text: 'Pictures',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < 8; i++)
                        InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>const VideoScreen()));
                          },
                          child: Column(
                            children: [
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 17),
                                child: Image.asset('assets/bookimage1.png',
                                    fit: BoxFit.cover),
                              ),
                              const SizedBox(height: 5),
                              TextWidget(
                                  text: "Watchman Nee",
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: blackColor,
                                  fontFamily: 'Poppins'),
                              TextWidget(
                                  text: 'Bro.Mathew',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: blackColor,
                                  fontFamily: 'Poppins'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 23),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                          text: 'Trending',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                          fontFamily: 'Poppins'),
                    ]),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 17,
                    ),
                    for (int i = 0; i < 8; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: Image.asset('assets/bookimage2.png',
                            fit: BoxFit.cover),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 23),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                          text: 'Trending Books',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                          fontFamily: 'Poppins'),
                    ]),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 17),
                    for (int i = 0; i < 8; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: Image.asset('assets/bookimage3.png',
                            fit: BoxFit.cover),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 23),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                          text: 'More Books',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                          fontFamily: 'Poppins'),
                    ]),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 17),
                    for (int i = 0; i < 8; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: Image.asset('assets/bookimage3.png',
                            fit: BoxFit.cover),
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
