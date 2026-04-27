import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/models/location.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/screens/location_detail_screen.dart';
import 'package:storify/screens/location_form_screen.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/utils/constants.dart';

// Location list with CRUD actions
class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.locationsTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'locations_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LocationFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(color: context.colorTextPrimary),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchLocationHint,
                prefixIcon:
                    Icon(Icons.search, color: context.colorTextMuted),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: context.colorTextMuted,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Consumer<LocationProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading && prov.locations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final filtered = prov.locations
            .where(
              (l) => l.name
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
            )
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noLocationsFound,
              style: GoogleFonts.inter(color: context.colorTextSecondary),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => prov.loadLocations(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _buildLocationCard(context, filtered[i]),
          ),
        );
      },
    );
  }

  Widget _buildLocationCard(BuildContext context, Location location) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationDetailScreen(location: location),
        ),
      ),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.warehouse_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: GoogleFonts.inter(
                    color: context.colorTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (location.description != null &&
                    location.description!.isNotEmpty)
                  Text(
                    location.description!,
                    style: GoogleFonts.inter(
                      color: context.colorTextSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Edit
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: context.colorTextSecondary,
              size: 20,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocationFormScreen(location: location),
              ),
            ),
          ),
          // Delete
          IconButton(
            icon: const Icon(
              Icons.delete_outlined,
              color: AppColors.error,
              size: 20,
            ),
            onPressed: () => _confirmDelete(context, location),
          ),
        ],
      ),
    ),
    );
  }

  void _confirmDelete(BuildContext context, Location location) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colorCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: context.colorBorder),
        ),
        title: Text(
          AppLocalizations.of(context)!.deleteLocationTitle,
          style: GoogleFonts.inter(
            color: context.colorTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteLocationConfirm(location.name),
          style: GoogleFonts.inter(color: context.colorTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.btnCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context
                    .read<LocationProvider>()
                    .deleteLocation(location.id);
              } catch (e) {
                if (context.mounted) {
                  showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.btnDelete),
          ),
        ],
      ),
    );
  }
}
