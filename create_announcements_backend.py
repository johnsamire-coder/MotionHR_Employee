# -*- coding: utf-8 -*-
"""
سكريبت شامل ينشئ:
1. models_announcements.py (Models)
2. api_announcements.py (APIs)
"""
import os

# ═══════════════════════════════════════════════════════════
# 1) MODELS FILE
# ═══════════════════════════════════════════════════════════

MODELS_CONTENT = '''# -*- coding: utf-8 -*-
"""
Company Announcements - إعلانات الشركة الرسمية
من المدير للموظفين مع استهداف متقدم
"""

from django.db import models
from django.conf import settings
from django.utils import timezone
from django.contrib.contenttypes.fields import GenericRelation
from core.models import TenantModel


class CompanyAnnouncement(TenantModel):
    """إعلان رسمي من المدير للموظفين"""

    PRIORITY_CHOICES = [
        ('normal', 'عادي'),
        ('important', 'مهم'),
        ('urgent', 'عاجل'),
    ]

    # المحتوى
    title = models.CharField(max_length=200, verbose_name='العنوان')
    content = models.TextField(verbose_name='المحتوى')
    priority = models.CharField(
        max_length=20,
        choices=PRIORITY_CHOICES,
        default='normal',
        verbose_name='الأولوية'
    )

    # الاستهداف الأساسي
    target_all_company = models.BooleanField(
        default=False,
        verbose_name='لكل الشركة'
    )
    target_branches = models.ManyToManyField(
        'companies.Branch',
        blank=True,
        related_name='targeted_announcements',
        verbose_name='الفروع المستهدفة'
    )
    target_departments = models.ManyToManyField(
        'companies.Department',
        blank=True,
        related_name='targeted_announcements',
        verbose_name='الأقسام المستهدفة'
    )
    target_employees = models.ManyToManyField(
        'employees.Employee',
        blank=True,
        related_name='directly_targeted_announcements',
        verbose_name='موظفين محددين'
    )

    # الاستثناءات
    excluded_branches = models.ManyToManyField(
        'companies.Branch',
        blank=True,
        related_name='excluded_from_announcements',
        verbose_name='فروع مستثناة'
    )
    excluded_departments = models.ManyToManyField(
        'companies.Department',
        blank=True,
        related_name='excluded_from_announcements',
        verbose_name='أقسام مستثناة'
    )
    excluded_employees = models.ManyToManyField(
        'employees.Employee',
        blank=True,
        related_name='excluded_from_announcements',
        verbose_name='موظفين مستثنون'
    )

    # الإعدادات
    requires_confirmation = models.BooleanField(
        default=False,
        verbose_name='يتطلب تأكيد قراءة'
    )
    is_active = models.BooleanField(default=True, verbose_name='نشط')
    send_push = models.BooleanField(
        default=True,
        verbose_name='إرسال Push Notification'
    )

    # التوقيت
    publish_at = models.DateTimeField(
        default=timezone.now,
        verbose_name='تاريخ النشر'
    )
    expires_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='تاريخ الانتهاء'
    )

    # المرسل
    sent_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='sent_announcements',
        verbose_name='المرسل'
    )

    # إحصائيات (auto-calculated)
    total_targeted = models.IntegerField(default=0)
    total_read = models.IntegerField(default=0)
    total_confirmed = models.IntegerField(default=0)

    # Reminders sent count
    reminders_sent = models.IntegerField(default=0)
    last_reminder_at = models.DateTimeField(null=True, blank=True)

    # المرفقات (Generic Relation - نستخدم Attachment الحالي)
    attachments = GenericRelation('core.Attachment')

    class Meta:
        db_table = 'company_announcements'
        ordering = ['-publish_at', '-created_at']
        verbose_name = 'إعلان شركة'
        verbose_name_plural = 'إعلانات الشركة'
        indexes = [
            models.Index(fields=['company', 'is_active', 'publish_at']),
            models.Index(fields=['company', 'priority']),
        ]

    def __str__(self):
        return f'{self.title} ({self.get_priority_display()})'

    def is_valid(self):
        """هل الإعلان ساري حالياً؟"""
        now = timezone.now()
        if not self.is_active:
            return False
        if self.publish_at > now:
            return False
        if self.expires_at and self.expires_at < now:
            return False
        return True

    def get_target_employees(self):
        """يحسب الموظفين المستهدفين النهائيين بعد Include/Exclude"""
        from employees.models import Employee

        # Step 1: Include
        if self.target_all_company:
            employees = Employee.all_objects.filter(company=self.company)
        else:
            employee_ids = set()

            # من الفروع
            if self.target_branches.exists():
                branch_ids = self.target_branches.values_list('id', flat=True)
                employee_ids.update(
                    Employee.all_objects.filter(
                        company=self.company,
                        branch_id__in=branch_ids
                    ).values_list('id', flat=True)
                )

            # من الأقسام
            if self.target_departments.exists():
                dept_ids = self.target_departments.values_list('id', flat=True)
                employee_ids.update(
                    Employee.all_objects.filter(
                        company=self.company,
                        department_id__in=dept_ids
                    ).values_list('id', flat=True)
                )

            # موظفين محددين
            if self.target_employees.exists():
                employee_ids.update(
                    self.target_employees.values_list('id', flat=True)
                )

            employees = Employee.all_objects.filter(id__in=employee_ids)

        # Step 2: Exclude
        excluded_ids = set()

        if self.excluded_branches.exists():
            excluded_ids.update(
                Employee.all_objects.filter(
                    branch__in=self.excluded_branches.all()
                ).values_list('id', flat=True)
            )

        if self.excluded_departments.exists():
            excluded_ids.update(
                Employee.all_objects.filter(
                    department__in=self.excluded_departments.all()
                ).values_list('id', flat=True)
            )

        if self.excluded_employees.exists():
            excluded_ids.update(
                self.excluded_employees.values_list('id', flat=True)
            )

        if excluded_ids:
            employees = employees.exclude(id__in=excluded_ids)

        return employees.distinct()

    def update_stats(self):
        """تحديث الإحصائيات"""
        self.total_targeted = self.get_target_employees().count()
        self.total_read = self.reads.count()
        self.total_confirmed = self.reads.filter(confirmed=True).count()
        self.save(update_fields=['total_targeted', 'total_read', 'total_confirmed'])


class CompanyAnnouncementRead(TenantModel):
    """سجل قراءة الإعلان"""

    announcement = models.ForeignKey(
        CompanyAnnouncement,
        on_delete=models.CASCADE,
        related_name='reads'
    )
    employee = models.ForeignKey(
        'employees.Employee',
        on_delete=models.CASCADE,
        related_name='announcement_reads'
    )
    read_at = models.DateTimeField(auto_now_add=True)
    confirmed = models.BooleanField(default=False)
    confirmed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'company_announcement_reads'
        unique_together = [('announcement', 'employee')]
        indexes = [
            models.Index(fields=['announcement', 'employee']),
        ]

    def __str__(self):
        return f'{self.employee} read {self.announcement}'
'''


# ═══════════════════════════════════════════════════════════
# 2) APIS FILE
# ═══════════════════════════════════════════════════════════

APIS_CONTENT = '''# -*- coding: utf-8 -*-
"""
API for Company Announcements (Phase 4.2)
"""

from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.db.models import Q, Count
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication
from rest_framework.response import Response

from accounts.models import CompanyAnnouncement, CompanyAnnouncementRead


# ═══════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════

def _get_employee(user):
    """جلب موظف المستخدم"""
    return getattr(user, "employee_profile", None)


def _is_manager(user):
    """هل هذا المستخدم مدير؟"""
    return hasattr(user, "role") and user.role in (
        "super_admin", "company_admin", "manager", "hr_manager"
    )


def serialize_announcement(ann, employee=None, include_stats=False, request=None):
    """تحويل إعلان لـ dict"""
    base_url = ""
    if request:
        base_url = f"{request.scheme}://{request.get_host()}"

    # حالة القراءة للموظف الحالي
    read_status = None
    if employee:
        read = CompanyAnnouncementRead.all_objects.filter(
            announcement=ann,
            employee=employee
        ).first()
        read_status = {
            "is_read": read is not None,
            "read_at": read.read_at.isoformat() if read else None,
            "is_confirmed": read.confirmed if read else False,
        }

    # المرفقات
    attachments_list = []
    for att in ann.attachments.all():
        attachments_list.append({
            "id": att.id,
            "original_name": att.original_name,
            "file_type": att.file_type,
            "file_size": att.file_size,
            "file_url": f"{base_url}{att.file.url}" if att.file else None,
            "thumbnail_url": f"{base_url}{att.thumbnail.url}" if att.thumbnail else None,
        })

    data = {
        "id": ann.id,
        "title": ann.title,
        "content": ann.content,
        "priority": ann.priority,
        "priority_display": ann.get_priority_display(),
        "requires_confirmation": ann.requires_confirmation,
        "is_active": ann.is_active,
        "publish_at": ann.publish_at.isoformat(),
        "expires_at": ann.expires_at.isoformat() if ann.expires_at else None,
        "sent_by": ann.sent_by.username if ann.sent_by else None,
        "sent_by_name": (
            ann.sent_by.get_full_name() if ann.sent_by else None
        ),
        "created_at": ann.created_at.isoformat(),
        "attachments_count": len(attachments_list),
        "attachments": attachments_list,
        "read_status": read_status,
    }

    if include_stats:
        data["stats"] = {
            "total_targeted": ann.total_targeted,
            "total_read": ann.total_read,
            "total_confirmed": ann.total_confirmed,
            "read_percentage": (
                round((ann.total_read / ann.total_targeted * 100), 1)
                if ann.total_targeted > 0 else 0
            ),
        }
        data["targeting"] = {
            "target_all_company": ann.target_all_company,
            "target_branches": list(ann.target_branches.values_list("id", flat=True)),
            "target_departments": list(ann.target_departments.values_list("id", flat=True)),
            "target_employees": list(ann.target_employees.values_list("id", flat=True)),
            "excluded_branches": list(ann.excluded_branches.values_list("id", flat=True)),
            "excluded_departments": list(ann.excluded_departments.values_list("id", flat=True)),
            "excluded_employees": list(ann.excluded_employees.values_list("id", flat=True)),
        }

    return data


# ═══════════════════════════════════════════════════════════
# EMPLOYEE ENDPOINTS
# ═══════════════════════════════════════════════════════════

@api_view(["GET"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def my_announcements(request):
    """GET /announcements/my/ - إعلاناتي كموظف"""
    employee = _get_employee(request.user)
    if not employee:
        return Response({"error": "no employee profile"}, status=404)

    # جلب كل الإعلانات المستهدف بيها
    all_announcements = CompanyAnnouncement.all_objects.filter(
        company=employee.company,
        is_active=True,
        publish_at__lte=timezone.now(),
    ).filter(
        Q(expires_at__isnull=True) | Q(expires_at__gte=timezone.now())
    ).order_by("-publish_at")

    # فلترة على المستهدفين
    my_announcements = []
    for ann in all_announcements:
        targets = ann.get_target_employees()
        if targets.filter(id=employee.id).exists():
            my_announcements.append(ann)

    data = [
        serialize_announcement(ann, employee, request=request)
        for ann in my_announcements
    ]

    return Response({
        "count": len(data),
        "announcements": data,
    })


@api_view(["GET"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def unread_count(request):
    """GET /announcements/unread-count/ - عدد الإعلانات غير المقروءة"""
    employee = _get_employee(request.user)
    if not employee:
        return Response({"unread_count": 0})

    # كل الإعلانات النشطة
    all_active = CompanyAnnouncement.all_objects.filter(
        company=employee.company,
        is_active=True,
        publish_at__lte=timezone.now(),
    ).filter(
        Q(expires_at__isnull=True) | Q(expires_at__gte=timezone.now())
    )

    # كام واحد قرأ
    read_ids = CompanyAnnouncementRead.all_objects.filter(
        employee=employee
    ).values_list("announcement_id", flat=True)

    # فلترة على المستهدفين
    unread = 0
    for ann in all_active.exclude(id__in=read_ids):
        if ann.get_target_employees().filter(id=employee.id).exists():
            unread += 1

    return Response({"unread_count": unread})


@api_view(["GET"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def announcement_detail(request, ann_id):
    """GET /announcements/<id>/ - تفاصيل إعلان"""
    employee = _get_employee(request.user)
    if not employee:
        return Response({"error": "no employee profile"}, status=404)

    try:
        ann = CompanyAnnouncement.all_objects.get(
            id=ann_id,
            company=employee.company
        )
    except CompanyAnnouncement.DoesNotExist:
        return Response({"error": "not found"}, status=404)

    # تأكد إن الموظف مستهدف
    if not ann.get_target_employees().filter(id=employee.id).exists():
        return Response({"error": "not targeted"}, status=403)

    # تسجيل القراءة تلقائياً
    read, created = CompanyAnnouncementRead.all_objects.get_or_create(
        announcement=ann,
        employee=employee,
        defaults={"company": employee.company}
    )

    if created:
        ann.total_read = ann.reads.count()
        ann.save(update_fields=["total_read"])

    return Response(serialize_announcement(ann, employee, request=request))


@api_view(["POST"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def confirm_announcement(request, ann_id):
    """POST /announcements/<id>/confirm/ - تأكيد قراءة"""
    employee = _get_employee(request.user)
    if not employee:
        return Response({"error": "no employee profile"}, status=404)

    try:
        ann = CompanyAnnouncement.all_objects.get(
            id=ann_id,
            company=employee.company
        )
    except CompanyAnnouncement.DoesNotExist:
        return Response({"error": "not found"}, status=404)

    if not ann.requires_confirmation:
        return Response({"error": "this announcement does not require confirmation"}, status=400)

    read, _ = CompanyAnnouncementRead.all_objects.get_or_create(
        announcement=ann,
        employee=employee,
        defaults={"company": employee.company}
    )

    if read.confirmed:
        return Response({"success": True, "message": "already confirmed"})

    read.confirmed = True
    read.confirmed_at = timezone.now()
    read.save()

    ann.total_confirmed = ann.reads.filter(confirmed=True).count()
    ann.save(update_fields=["total_confirmed"])

    return Response({
        "success": True,
        "message": "تم تأكيد القراءة",
        "confirmed_at": read.confirmed_at.isoformat(),
    })


# ═══════════════════════════════════════════════════════════
# MANAGER ENDPOINTS
# ═══════════════════════════════════════════════════════════

@api_view(["GET"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manager_list(request):
    """GET /manager/announcements/ - قائمة إعلانات المدير"""
    if not _is_manager(request.user):
        return Response({"error": "unauthorized"}, status=403)

    company_id = request.user.company_id
    if request.user.role == "super_admin":
        company_id = request.query_params.get("company_id", company_id)

    announcements = CompanyAnnouncement.all_objects.filter(
        company_id=company_id
    ).order_by("-created_at")

    data = [
        serialize_announcement(ann, include_stats=True, request=request)
        for ann in announcements
    ]

    return Response({
        "count": len(data),
        "announcements": data,
    })


@api_view(["POST"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manager_create(request):
    """POST /manager/announcements/create/ - إنشاء إعلان جديد"""
    if not _is_manager(request.user):
        return Response({"error": "unauthorized"}, status=403)

    data = request.data
    company_id = request.user.company_id
    if request.user.role == "super_admin":
        company_id = data.get("company_id", company_id)

    # Validation
    if not data.get("title"):
        return Response({"error": "العنوان مطلوب"}, status=400)
    if not data.get("content"):
        return Response({"error": "المحتوى مطلوب"}, status=400)

    # التحقق من الاستهداف
    has_target = (
        data.get("target_all_company", False) or
        data.get("target_branches", []) or
        data.get("target_departments", []) or
        data.get("target_employees", [])
    )
    if not has_target:
        return Response(
            {"error": "لازم تختار على الأقل جهة مستهدفة واحدة"},
            status=400
        )

    try:
        # إنشاء الإعلان
        ann = CompanyAnnouncement(
            company_id=company_id,
            title=data["title"],
            content=data["content"],
            priority=data.get("priority", "normal"),
            target_all_company=data.get("target_all_company", False),
            requires_confirmation=data.get("requires_confirmation", False),
            is_active=data.get("is_active", True),
            send_push=data.get("send_push", True),
            sent_by=request.user,
        )

        # publish_at
        if data.get("publish_at"):
            ann.publish_at = data["publish_at"]

        # expires_at
        if data.get("expires_at"):
            ann.expires_at = data["expires_at"]

        ann.save()

        # M2M relations
        if data.get("target_branches"):
            ann.target_branches.set(data["target_branches"])
        if data.get("target_departments"):
            ann.target_departments.set(data["target_departments"])
        if data.get("target_employees"):
            ann.target_employees.set(data["target_employees"])

        if data.get("excluded_branches"):
            ann.excluded_branches.set(data["excluded_branches"])
        if data.get("excluded_departments"):
            ann.excluded_departments.set(data["excluded_departments"])
        if data.get("excluded_employees"):
            ann.excluded_employees.set(data["excluded_employees"])

        # حساب المستهدفين
        ann.update_stats()

        # TODO: إرسال Push notifications
        # if ann.send_push:
        #     send_announcement_push(ann)

        return Response({
            "success": True,
            "message": "تم إنشاء الإعلان بنجاح",
            "announcement": serialize_announcement(ann, include_stats=True, request=request),
        }, status=201)

    except Exception as e:
        return Response({"error": f"خطأ: {str(e)}"}, status=500)


@api_view(["GET"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manager_detail(request, ann_id):
    """GET /manager/announcements/<id>/ - تفاصيل إعلان مع إحصائيات"""
    if not _is_manager(request.user):
        return Response({"error": "unauthorized"}, status=403)

    try:
        ann = CompanyAnnouncement.all_objects.get(id=ann_id)
    except CompanyAnnouncement.DoesNotExist:
        return Response({"error": "not found"}, status=404)

    # Multi-tenant check
    if request.user.role != "super_admin" and ann.company_id != request.user.company_id:
        return Response({"error": "unauthorized"}, status=403)

    return Response(serialize_announcement(ann, include_stats=True, request=request))


@api_view(["GET"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manager_reads(request, ann_id):
    """GET /manager/announcements/<id>/reads/ - قائمة اللي قرأوا واللي ما قروش"""
    if not _is_manager(request.user):
        return Response({"error": "unauthorized"}, status=403)

    try:
        ann = CompanyAnnouncement.all_objects.get(id=ann_id)
    except CompanyAnnouncement.DoesNotExist:
        return Response({"error": "not found"}, status=404)

    if request.user.role != "super_admin" and ann.company_id != request.user.company_id:
        return Response({"error": "unauthorized"}, status=403)

    targets = ann.get_target_employees()
    reads = CompanyAnnouncementRead.all_objects.filter(announcement=ann)
    read_map = {r.employee_id: r for r in reads}

    read_list = []
    unread_list = []

    for emp in targets:
        emp_data = {
            "id": emp.id,
            "employee_code": emp.employee_code,
            "full_name": emp.full_name_ar or emp.full_name_en,
            "department": emp.department.name if emp.department else None,
            "branch": emp.branch.name if emp.branch else None,
        }

        if emp.id in read_map:
            read = read_map[emp.id]
            emp_data["read_at"] = read.read_at.isoformat()
            emp_data["confirmed"] = read.confirmed
            emp_data["confirmed_at"] = (
                read.confirmed_at.isoformat() if read.confirmed_at else None
            )
            read_list.append(emp_data)
        else:
            unread_list.append(emp_data)

    return Response({
        "total_targeted": len(read_list) + len(unread_list),
        "read_count": len(read_list),
        "unread_count": len(unread_list),
        "confirmed_count": sum(1 for r in read_list if r.get("confirmed")),
        "read_list": read_list,
        "unread_list": unread_list,
    })


@api_view(["PATCH"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manager_toggle(request, ann_id):
    """PATCH /manager/announcements/<id>/toggle/ - تفعيل/تعطيل"""
    if not _is_manager(request.user):
        return Response({"error": "unauthorized"}, status=403)

    try:
        ann = CompanyAnnouncement.all_objects.get(id=ann_id)
    except CompanyAnnouncement.DoesNotExist:
        return Response({"error": "not found"}, status=404)

    if request.user.role != "super_admin" and ann.company_id != request.user.company_id:
        return Response({"error": "unauthorized"}, status=403)

    ann.is_active = not ann.is_active
    ann.save(update_fields=["is_active"])

    return Response({
        "success": True,
        "is_active": ann.is_active,
        "message": "تم التفعيل" if ann.is_active else "تم التعطيل",
    })


@api_view(["DELETE"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def manager_delete(request, ann_id):
    """DELETE /manager/announcements/<id>/ - حذف إعلان"""
    if not _is_manager(request.user):
        return Response({"error": "unauthorized"}, status=403)

    try:
        ann = CompanyAnnouncement.all_objects.get(id=ann_id)
    except CompanyAnnouncement.DoesNotExist:
        return Response({"error": "not found"}, status=404)

    if request.user.role != "super_admin" and ann.company_id != request.user.company_id:
        return Response({"error": "unauthorized"}, status=403)

    ann.delete()
    return Response({"success": True, "message": "تم الحذف"})


@api_view(["POST"])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def calculate_targets(request):
    """POST /manager/announcements/calculate-targets/ - حساب عدد المستهدفين قبل الإنشاء"""
    if not _is_manager(request.user):
        return Response({"error": "unauthorized"}, status=403)

    from employees.models import Employee

    data = request.data
    company_id = request.user.company_id
    if request.user.role == "super_admin":
        company_id = data.get("company_id", company_id)

    employee_ids = set()

    # Include
    if data.get("target_all_company"):
        employee_ids = set(
            Employee.all_objects.filter(company_id=company_id).values_list("id", flat=True)
        )
    else:
        if data.get("target_branches"):
            employee_ids.update(
                Employee.all_objects.filter(
                    company_id=company_id,
                    branch_id__in=data["target_branches"]
                ).values_list("id", flat=True)
            )
        if data.get("target_departments"):
            employee_ids.update(
                Employee.all_objects.filter(
                    company_id=company_id,
                    department_id__in=data["target_departments"]
                ).values_list("id", flat=True)
            )
        if data.get("target_employees"):
            employee_ids.update(data["target_employees"])

    # Exclude
    excluded_ids = set()

    if data.get("excluded_branches"):
        excluded_ids.update(
            Employee.all_objects.filter(
                branch_id__in=data["excluded_branches"]
            ).values_list("id", flat=True)
        )
    if data.get("excluded_departments"):
        excluded_ids.update(
            Employee.all_objects.filter(
                department_id__in=data["excluded_departments"]
            ).values_list("id", flat=True)
        )
    if data.get("excluded_employees"):
        excluded_ids.update(data["excluded_employees"])

    final_ids = employee_ids - excluded_ids
    final_employees = Employee.all_objects.filter(id__in=final_ids)

    return Response({
        "count": len(final_ids),
        "employees": [
            {
                "id": e.id,
                "employee_code": e.employee_code,
                "full_name": e.full_name_ar or e.full_name_en,
                "department": e.department.name if e.department else None,
                "branch": e.branch.name if e.branch else None,
            }
            for e in final_employees[:100]  # حد أقصى 100 في الـ preview
        ],
    })
'''


# ═══════════════════════════════════════════════════════════
# 3) WRITE FILES
# ═══════════════════════════════════════════════════════════

with open("models_announcements.py", "w", encoding="utf-8") as f:
    f.write(MODELS_CONTENT)

with open("api_announcements.py", "w", encoding="utf-8") as f:
    f.write(APIS_CONTENT)

print("OK - Files created:")
print(f"  models_announcements.py: {len(MODELS_CONTENT)} bytes")
print(f"  api_announcements.py: {len(APIS_CONTENT)} bytes")