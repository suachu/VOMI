import 'dart:ui';
import 'package:flutter/material.dart';

class CharacterSelectPage extends StatefulWidget {
  final String userName;

  const CharacterSelectPage({super.key, required this.userName});

  @override
  State<CharacterSelectPage> createState() => _CharacterSelectPage();
}

class _CharacterSelectPage extends State<CharacterSelectPage> {
  final PageController _pageController = PageController();
  int currentIndex = 0;

  // Local unlock state (for now)
  final List<bool> unlocked = [
    true,   // dog
    false,   // cat
    false,   // fox
  ];

  final List<String> animalImages = [
    'assets/images/dog.png',
    'assets/images/cat.png',
    'assets/images/fox.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 138),

            // 🔵 Username
            Text.rich(
              TextSpan(
                text: '${widget.userName} ',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                children: const [
                  TextSpan(
                    text: '님과 함께할\n캐릭터를 골라주세요',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // 🎠 Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: animalImages.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          animalImages[index],
                          width: 200,
                        ),

                        if (!unlocked[index])
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 8,
                                sigmaY: 8,
                              ),
                              child: Container(
                                width: 200,
                                height: 200,
                                color: Colors.white.withOpacity(0.2),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.lock,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 33),

            // Dot indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                animalImages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentIndex == index ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? Color.fromRGBO(172, 215, 230, 1)
                        : Color.fromRGBO(223, 230, 233, 1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Start button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 70,
                child: TextButton(
                  style: ButtonStyle(
              
        
                  ),
                  onPressed: unlocked[currentIndex]
                      ? () {
                          print(
                              "Selected animal index: $currentIndex");
                        }
                      : null,
                  child: const Text('시작하기'),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
