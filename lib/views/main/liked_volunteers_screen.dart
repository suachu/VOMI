import 'package:flutter/material.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/services/liked_volunteer_service.dart';
import 'package:vomi/views/main/list_detail_screen.dart';
import 'package:vomi/views/main/list_models.dart';

class LikedVolunteersScreen extends StatefulWidget {
  const LikedVolunteersScreen({super.key});

  @override
  State<LikedVolunteersScreen> createState() => _LikedVolunteersScreenState();
}

class _LikedVolunteersScreenState extends State<LikedVolunteersScreen> {
  @override
  void initState() {
    super.initState();
    LikedVolunteerService.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('찜한 봉사'),
      ),
      body: ValueListenableBuilder<List<LikedVolunteer>>(
        valueListenable: LikedVolunteerService.likedItems,
        builder: (context, items, child) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                '아직 찜한 봉사가 없어요.',
                style: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 14,
                  color: Color(0xFF6A7282),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ListDetailScreen(
                          item: ListItem(
                            title: item.title,
                            subtitle: item.subtitle,
                            distanceKm: 0,
                            popularity: 0,
                            createdAt: DateTime.now(),
                            thumbnailAsset: item.thumbnailAsset,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            item.thumbnailAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.pets),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontFamily: 'Pretendard Variable',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                  fontFamily: 'Pretendard Variable',
                                  fontSize: 13,
                                  color: Color(0xFF6A7282),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
