// lib/widgets/adaptive_attendance_buttons.dart
import 'package:flutter/material.dart';

/// Widget بيعرض الأزرار المناسبة حسب نوع الموظف
class AdaptiveAttendanceButtons extends StatelessWidget {
  final String workerType;
  final bool checkedIn;
  final bool checkedOut;
  final bool loading;
  final Map<String, dynamic>? activeFieldVisit;
  final Map<String, dynamic>? currentApprovedLocation;

  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final VoidCallback? onStartVisit;
  final VoidCallback? onEndVisit;

  const AdaptiveAttendanceButtons({
    super.key,
    required this.workerType,
    required this.checkedIn,
    required this.checkedOut,
    required this.loading,
    required this.onCheckIn,
    required this.onCheckOut,
    this.activeFieldVisit,
    this.currentApprovedLocation,
    this.onStartVisit,
    this.onEndVisit,
  });

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';

    if (workerType == 'office') {
      return _officeButtons(ar);
    } else if (workerType == 'field_free') {
      return _fieldFreeButtons(ar);
    } else if (workerType == 'field_assigned') {
      return _fieldAssignedButtons(ar);
    }
    return _officeButtons(ar);
  }

  Widget _officeButtons(bool ar) {
    return Row(children: [
      Expanded(
        child: _bigButton(
          onPressed: (loading || checkedIn) ? null : onCheckIn,
          color: checkedIn ? Colors.grey.shade400 : Colors.green,
          icon: checkedIn ? Icons.check_circle : Icons.login,
          label: checkedIn
              ? (ar ? 'تم الحضور' : 'Checked In')
              : (ar ? 'تسجيل الحضور' : 'Check In'),
          disabled: checkedIn,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _bigButton(
          onPressed:
              (loading || !checkedIn || checkedOut) ? null : onCheckOut,
          color: (!checkedIn || checkedOut)
              ? Colors.grey.shade400
              : Colors.red,
          icon: checkedOut ? Icons.check_circle : Icons.logout,
          label: checkedOut
              ? (ar ? 'تم الانصراف' : 'Checked Out')
              : (ar ? 'تسجيل الانصراف' : 'Check Out'),
          disabled: !checkedIn || checkedOut,
        ),
      ),
    ]);
  }

  Widget _fieldFreeButtons(bool ar) {
    final hasActiveVisit = activeFieldVisit != null;

    if (!checkedIn) {
      return Row(children: [
        Expanded(
          child: _bigButton(
            onPressed: loading ? null : onCheckIn,
            color: Colors.green,
            icon: Icons.login,
            label: ar ? 'تسجيل حضور' : 'Check In',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _bigButton(
            onPressed: null,
            color: Colors.grey.shade400,
            icon: Icons.logout,
            label: ar ? 'تسجيل خروج' : 'Check Out',
            disabled: true,
          ),
        ),
      ]);
    }

    return Column(children: [
      if (hasActiveVisit) _activeVisitBanner(ar),
      Row(children: [
        Expanded(
          child: _bigButton(
            onPressed:
                (loading || hasActiveVisit) ? null : onStartVisit,
            color: hasActiveVisit ? Colors.grey.shade400 : Color(0xFF382483),
            icon: Icons.add_location,
            label: ar ? 'تسجيل زيارة' : 'Start Visit',
            disabled: hasActiveVisit,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _bigButton(
            onPressed:
                (loading || !hasActiveVisit) ? null : onEndVisit,
            color: hasActiveVisit ? Colors.orange : Colors.grey.shade400,
            icon: Icons.location_off,
            label: ar ? 'إنهاء زيارة' : 'End Visit',
            disabled: !hasActiveVisit,
          ),
        ),
      ]),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: _bigButton(
          onPressed: (loading || checkedOut) ? null : onCheckOut,
          color: checkedOut ? Colors.grey.shade400 : Colors.red,
          icon: checkedOut ? Icons.check_circle : Icons.logout,
          label: checkedOut
              ? (ar ? 'تم الانصراف النهائي' : 'Final Check Out Done')
              : (ar ? 'إنهاء الشيفت النهائي' : 'Final Check Out'),
          disabled: checkedOut,
        ),
      ),
    ]);
  }

  Widget _fieldAssignedButtons(bool ar) {
    final hasActiveVisit = activeFieldVisit != null;
    final currentLocName = currentApprovedLocation?['name'];
    final isInApprovedLocation = currentApprovedLocation != null;

    if (!checkedIn) {
      return Column(children: [
        if (currentLocName != null)
          _locationBanner(currentLocName, true)
        else
          _locationBanner(
              ar ? 'موقع غير معتمد' : 'Unapproved location', false),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Column(
              children: [
                _bigButton(
                  onPressed: (loading || !isInApprovedLocation)
                      ? null
                      : onCheckIn,
                  color: isInApprovedLocation
                      ? Colors.green
                      : Colors.grey.shade400,
                  icon: Icons.login,
                  label: ar ? 'تسجيل حضور' : 'Check In',
                  disabled: !isInApprovedLocation,
                ),
                if (currentLocName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      currentLocName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _bigButton(
              onPressed: null,
              color: Colors.grey.shade400,
              icon: Icons.logout,
              label: ar ? 'تسجيل خروج' : 'Check Out',
              disabled: true,
            ),
          ),
        ]),
      ]);
    }

    return Column(children: [
      if (hasActiveVisit)
        _activeVisitBanner(ar)
      else if (currentLocName != null)
        _locationBanner(currentLocName, true)
      else
        _locationBanner(
            ar ? 'موقع غير معتمد' : 'Unapproved location', false),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: Column(
            children: [
              _bigButton(
                onPressed:
                    (loading || hasActiveVisit || !isInApprovedLocation)
                        ? null
                        : onStartVisit,
                color: (hasActiveVisit || !isInApprovedLocation)
                    ? Colors.grey.shade400
                    : Color(0xFF382483),
                icon: Icons.add_location,
                label: ar ? 'تسجيل زيارة' : 'Start Visit',
                disabled: hasActiveVisit || !isInApprovedLocation,
              ),
              if (!hasActiveVisit && currentLocName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    currentLocName,
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF382483),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _bigButton(
            onPressed:
                (loading || !hasActiveVisit) ? null : onEndVisit,
            color: hasActiveVisit ? Colors.orange : Colors.grey.shade400,
            icon: Icons.location_off,
            label: ar ? 'إنهاء زيارة' : 'End Visit',
            disabled: !hasActiveVisit,
          ),
        ),
      ]),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: _bigButton(
          onPressed: (loading || checkedOut) ? null : onCheckOut,
          color: checkedOut ? Colors.grey.shade400 : Colors.red,
          icon: checkedOut ? Icons.check_circle : Icons.logout,
          label: checkedOut
              ? (ar ? 'تم الانصراف النهائي' : 'Final Check Out Done')
              : (ar ? 'إنهاء الشيفت النهائي' : 'Final Check Out'),
          disabled: checkedOut,
        ),
      ),
    ]);
  }

  Widget _activeVisitBanner(bool ar) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Row(children: [
        const Icon(Icons.location_on, color: Colors.green, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar ? 'زيارة نشطة' : 'Active Visit',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                activeFieldVisit?['location_name'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _locationBanner(String text, bool isApproved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isApproved ? Colors.green : Colors.orange,
        ),
      ),
      child: Row(children: [
        Icon(
          isApproved ? Icons.check_circle : Icons.warning,
          size: 16,
          color: isApproved ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isApproved
                  ? Colors.green.shade800
                  : Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _bigButton({
    required VoidCallback? onPressed,
    required Color color,
    required IconData icon,
    required String label,
    bool disabled = false,
  }) {
    return SizedBox(
      height: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: disabled ? 0 : 4,
          disabledBackgroundColor: Colors.grey.shade400,
          disabledForegroundColor: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
