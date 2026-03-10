import 'package:flutter/material.dart';

import '../../../custom_widgets/screen_size.dart';
import '../../../custom_widgets/text_widget.dart';
import '../../../custom_widgets/top_search_widget.dart';
import '../../utils/colors.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class PicturesScreen extends StatefulWidget {
  const PicturesScreen({super.key});

  @override
  State<PicturesScreen> createState() => _PicturesScreenState();
}

class _PicturesScreenState extends State<PicturesScreen> {
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextWidget(
                        text: 'Pictures',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: blackColor,
                        fontFamily: 'Poppins'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StaggeredGrid.count(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: [
                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 2,
                    child: Image.asset('assets/picture1.png'),
                  ),
                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 1,
                    child: Image.asset('assets/picture2.png'),
                  ),
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 1,
                    child: Image.asset('assets/picture3.png'),
                  ),
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 1,
                    child: Image.asset('assets/picture4.png'),
                  ),
                  StaggeredGridTile.count(
                    crossAxisCellCount: 4,
                    mainAxisCellCount: 2,
                    child: Image.asset('assets/picture5.png'),
                  ),
                ],
              )
              // StaggeredGrid.count(
              //   crossAxisCount: 3,
              //   mainAxisSpacing: 1,
              //   crossAxisSpacing: 1,
              //   children:  [
              //     StaggeredGridTile.count(
              //       crossAxisCellCount: 3,
              //       mainAxisCellCount: 2,
              //       child: Image.asset('assets/picture1.png') ,
              //     ),
              //     StaggeredGridTile.count(
              //       crossAxisCellCount: 1,
              //       mainAxisCellCount: 1,
              //        child: Image.asset('assets/picture2.png') ,
              //     ),
              //     StaggeredGridTile.count(
              //       crossAxisCellCount: 1,
              //       mainAxisCellCount: 1,
              //        child: Image.asset('assets/picture3.png') ,
              //     ),
              //     StaggeredGridTile.count(
              //       crossAxisCellCount: 1,
              //       mainAxisCellCount: 1,
              //        child: Image.asset('assets/picture4.png') ,
              //     ),
              //     StaggeredGridTile.count(
              //       crossAxisCellCount: 4,
              //       mainAxisCellCount: 2,
              //        child: Image.asset('assets/picture5.png') ,
              //     ),
              //     StaggeredGridTile.count(
              //       crossAxisCellCount: 1,
              //       mainAxisCellCount: 1,
              //        child: Image.asset('assets/picture6.png') ,
              //     ),
              //     StaggeredGridTile.count(
              //       crossAxisCellCount: 1,
              //       mainAxisCellCount: 1,
              //        child: Image.asset('assets/picture7.png') ,
              //     ),

              //   ],
              // )
            ],
          ),
        ),
      ),
    );
  }

  // Widget sliverGridWidget(BuildContext context){
  //   return StaggeredGridView.countBuilder(
  //       padding: const EdgeInsets.all(8.0),
  //       crossAxisCount: 4,
  //       itemCount: 10, //staticData.length,
  //       itemBuilder: (context, index){
  //         return Card(
  //           elevation: 8.0,
  //           child:InkWell(
  //            child: Hero(
  //              tag: index,// staticData[index].images,
  //              child: new FadeInImage(
  //                width: MediaQuery.of(context).size.width,
  //                image: NetworkImage("https://images.unsplash.com/photo-1468327768560-75b778cbb551?ixlib=rb-1.2.1&w=1000&q=80"), // NetworkImage(staticData[index].images),
  //                fit: BoxFit.cover,
  //                placeholder: AssetImage("assets/images/app_logo.png"),
  //              ),
  //            ),
  //            onTap: (){
  //              //
  //             }
  //           )
  //         );
  //       },
  //        staggeredTileBuilder: (index) => StaggeredTile.count(2,index.isEven ? 2: 3),
  //        mainAxisSpacing: 8.0,
  //        crossAxisSpacing: 8.0,
  //        );
  //        }
}
