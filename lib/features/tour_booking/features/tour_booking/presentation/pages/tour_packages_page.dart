import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';

import '../../core/tour_colors.dart';
import '../../core/tour_injector.dart';
import '../../core/tour_status.dart';
import '../bloc/tour_packages_bloc.dart';
import '../tour_navigator.dart';
import '../widgets/tour_widgets.dart';
import 'tour_detail_page.dart';

/// Screen 2: "Tour Packages" with filter chips and search.
class TourPackagesPage extends StatelessWidget {
  const TourPackagesPage({
    super.key,
    this.categoryId,
    this.query = '',
    this.openSearch = false,
  });

  final String? categoryId;
  final String query;
  final bool openSearch;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TourInjector.I.packagesBloc()
        ..add(
          TourPackagesStarted(
            categoryId: categoryId,
            query: query,
            openSearch: openSearch,
          ),
        ),
      child: const _PackagesView(),
    );
  }
}

class _PackagesView extends StatelessWidget {
  const _PackagesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<TourPackagesBloc, TourPackagesState>(
        builder: (context, state) {
          final bloc = context.read<TourPackagesBloc>();
          return Column(
            children: [
              TourHeaderBar(
                title: 'Tour Packages',
                centerTitle: true,
                trailing: IconButton(
                  onPressed: () => bloc.add(const TourPackagesSearchToggled()),
                  icon: Icon(
                    state.searchOpen
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                    size: 24,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (state.searchOpen)
                _SearchField(
                  initial: state.query,
                  onChanged: (v) => bloc.add(TourPackagesSearchChanged(v)),
                ),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: state.categoryId == null,
                      onTap: () =>
                          bloc.add(const TourPackagesFilterChanged(null)),
                    ),
                    for (final c in state.categories)
                      _FilterChip(
                        label: c.name,
                        selected: state.categoryId == c.id,
                        onTap: () => bloc.add(TourPackagesFilterChanged(c.id)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child:
                    state.status == TourStatus.loading && state.packages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.packages.isEmpty
                    ? Center(
                        child: Text(
                          'No packages found.',
                          style: AppTypography.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        itemCount: state.packages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, i) {
                          final p = state.packages[i];
                          return TourPackageCard(
                            package: p,
                            horizontal: i.isOdd,
                            onTap: () => TourNavigator.push(
                              context,
                              TourDetailPage(
                                packageId: p.id,
                                heroImage: TourImage.assetForPackage(p.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3B46E8) : const Color(0xFFF4F6F9),
            borderRadius: BorderRadius.circular(21),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: selected ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.initial, required this.onChanged});
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        autofocus: true,
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Search destinations or packages...',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: TourColors.chip,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
