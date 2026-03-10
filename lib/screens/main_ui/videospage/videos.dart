import 'package:flutter/material.dart';
import '../../../custom_widgets/screen_size.dart';
import '../../../custom_widgets/text_widget.dart';
import '../../../custom_widgets/top_search_widget.dart';
import '../../utils/colors.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
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
                  width: getWidth(context),
                  margin: const EdgeInsets.symmetric(horizontal: 17),
                  child: Container(
                    decoration: BoxDecoration(
                        image: const DecorationImage(
                            image: AssetImage('assets/videoimage.png'),
                            fit: BoxFit.fill),
                        borderRadius: BorderRadius.circular(12)),
                    child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: Image.asset('assets/youtube.png'))),
                  )),
              const SizedBox(height: 13),
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextWidget(
                        text: "Sunday Worship Service",
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: amberredColor,
                        fontFamily: 'Poppins'),
                    const SizedBox(height: 6),
                    TextWidget(
                        text: "Bethel prayer housee",
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: blackColor,
                        fontFamily: 'Poppins'),
                    const SizedBox(height: 6),
                    TextWidget(
                        text: "Narperville, iL",
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: blackColor,
                        fontFamily: 'Poppins'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: 8,
                    gridDelegate:  const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3/2,
                        crossAxisCount: 2), itemBuilder: (BuildContext context, int index) { 
                          return Container(
                      decoration: BoxDecoration(
                          image: const DecorationImage(
                              image: AssetImage('assets/videoimage.png'),
                              fit: BoxFit.fill),
                          borderRadius: BorderRadius.circular(12)),
                      child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: Image.asset('assets/youtube.png'))),
                    );
                         },),
              )
            ],
          ),
        ),
      ),
    );
  }
}
