# -*- coding: utf-8 -*-
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
