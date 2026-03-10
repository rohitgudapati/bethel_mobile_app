import 'package:flutter/material.dart';

import '../../../custom_widgets/screen_size.dart';
import '../../../custom_widgets/text_widget.dart';
import '../../../custom_widgets/top_search_widget.dart';
import '../../utils/colors.dart';
import '../bookspage/booksscreen.dart';
import '../picturespage/pictures.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      height: getHeight(context),
      width: getWidth(context),
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/bg.png'), fit: BoxFit.cover)),
      child: Column(
        children: [
          const TopSearchWidget(show: true, backarrowshow: true),
          const SizedBox(height: 31),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 23),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextWidget(
                    text: 'Shorts',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                    fontFamily: 'Poppins'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for(int i =0; i<6; i++)
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> const PicturesScreen()));
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: getWidth(context) / 3,
                    decoration:  BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                            image: AssetImage('assets/shortsimage.png'), fit: BoxFit.cover)),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          TextWidget(
                              text: 'Sermons',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: whiteColor,
                              fontFamily: 'Poppins'),
                          
                          Padding(
                            padding: const EdgeInsets.only(top: 100),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 31,
                                  width: 31,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: whiteColor),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Center(
                                      child: Icon(
                                    Icons.play_arrow,
                                    color: whiteColor,
                                  )),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 13,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 23),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextWidget(
                    text: 'Interviews',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                    fontFamily: 'Poppins'),
              ],
            ),
          ),
         const SizedBox(height: 20),
         SingleChildScrollView(scrollDirection: Axis.horizontal,
           child: InkWell(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BooksScreen()));
            },
             child: Row(
               children: [
                for (int i=0; i<5;i++)
                 Container(
                  margin:  const EdgeInsets.symmetric(horizontal: 10),
                   child: Column(
                     children: [
                       Container(
                        width: getWidth(context)/2,
                        padding: const EdgeInsets.symmetric(vertical: 45),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadiusDirectional.circular(12),
                          image: const DecorationImage(image: AssetImage('assets/pray.png'),fit:BoxFit.cover)),
                          child:  Center(
                            child: Container(
                              height: 31,
                              width: 31,
                              decoration: BoxDecoration(
                                border: Border.all(color: whiteColor),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Center(
                                  child: Icon(
                                Icons.play_arrow,
                                color: whiteColor,
                              )),
                            ),
                          ),
                       ),
                       Column(
                         children: [
                           TextWidget(text: "God Prayer", fontSize: 18, fontWeight: FontWeight.w500, color: blackColor, fontFamily: 'Poppins'),
                           TextWidget(text: "Let's Pray Together ", fontSize: 8, fontWeight: FontWeight.w400, color: blackColor, fontFamily: 'Poppins')
                         ],
                       )
                     ],
                   ),
                 ),
               ],
             ),
           ),
         )
        ],
      ),
    ));
  }
}
