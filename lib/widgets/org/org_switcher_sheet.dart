import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/organization_model.dart';
import 'package:ta3dia/services/org_service.dart';
import 'package:ta3dia/widgets/org/org_card.dart';

Future<void> showOrgSwitcherSheet(
  BuildContext context, {
  required VoidCallback onOrganizationsTap,
  required void Function(Organization org) onSelect,
}) {
  final l = AppLocalizations.of(context)!;
  final isRtl = l.localeName == 'ar';
  final cs = Theme.of(context).colorScheme;
  final orgService = Provider.of<OrgService>(context, listen: false);
  final orgs = List<Organization>.from(orgService.myOrgs);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    l.switchOrganization,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                ],
              ),
            ),
            if (orgs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    l.noOrganizationsYet,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: orgs.length,
                  itemBuilder: (context, index) {
                    final org = orgs[index];
                    final isCurrent = org.id == orgService.currentOrgId;
                    return OrgCard(
                      org: org,
                      cs: cs,
                      color: cs.primary,
                      isRtl: isRtl,
                      membersLabel: l.membersCount(org.memberCount),
                      taadiasLabel: l.taadiaCount(org.taadiaCount),
                      statusLabel: isCurrent ? l.currentOrg : null,
                      statusColor: const Color(0xFF00A86B),
                      trailing: isCurrent
                          ? const Icon(Icons.check_circle, color: Colors.white, size: 22)
                          : Icon(
                              isRtl ? Icons.chevron_left : Icons.chevron_right,
                              color: Colors.white,
                              size: 24,
                            ),
                      onTap: isCurrent
                          ? () => Navigator.pop(ctx)
                          : () {
                              Navigator.pop(ctx);
                              onSelect(org);
                            },
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
            ListTile(
              leading: Icon(Icons.apps, color: cs.primary),
              title: Text(
                l.myOrganizations,
                style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
              ),
              trailing: Icon(
                isRtl ? Icons.chevron_left : Icons.chevron_right,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              onTap: () {
                Navigator.pop(ctx);
                onOrganizationsTap();
              },
            ),
          ],
        ),
      ),
    ),
  );
}
