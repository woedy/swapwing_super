import random
from datetime import timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from challenges.models import (
    Challenge,
    ChallengeCategory,
    ChallengeMilestone,
    ChallengeParticipation,
    ChallengePrize,
    ChallengeStatus,
)
from notifications.models import Notification
from tags.models import Tag
from trade_up_league.models import Episode
from user_profile.models import AdminInfo, PersonalInfo, SocialMedia, Wallet


class Command(BaseCommand):
    help = "Seed the staging environment with representative SwapWing data."

    def handle(self, *args, **options):
        with transaction.atomic():
            self.stdout.write(self.style.MIGRATE_HEADING("Creating seed users"))
            admin = self._ensure_admin_user()
            alice = self._ensure_trader(
                email="alice@swapwing.test",
                first_name="Alice",
                last_name="Okoro",
                bio=(
                    "Community barter specialist focused on empowering artisans "
                    "to trade up their craft equipment."
                ),
            )
            ben = self._ensure_trader(
                email="ben@swapwing.test",
                first_name="Ben",
                last_name="Sato",
                bio="Sustainability tinkerer trading his way to a solar-powered camper.",
            )

            self.stdout.write(self.style.MIGRATE_HEADING("Creating taxonomy & media"))
            challenge_tag = self._get_or_create_tag("Sustainable Swaps", admin)
            journey_tag = self._get_or_create_tag("Trade Up Challenge", admin)
            maker_tag = self._get_or_create_tag("Makers", admin)

            self.stdout.write(self.style.MIGRATE_HEADING("Creating serialized journeys"))
            self._ensure_episode(
                title="From Bike Parts to E-Bike",
                author=alice,
                summary="Alice documents how she turns leftover bike parts into an electric ride.",
                tags=[challenge_tag, maker_tag],
                shared_with=[ben],
            )
            self._ensure_episode(
                title="Solar Camper Week 3",
                author=ben,
                summary="Ben trades a 3D printer for high-efficiency solar panels in week three.",
                tags=[journey_tag],
                shared_with=[alice],
            )

            self.stdout.write(self.style.MIGRATE_HEADING("Creating community challenges"))
            self._ensure_challenge([alice, ben])

            self.stdout.write(self.style.MIGRATE_HEADING("Creating notifications"))
            self._ensure_notification(
                recipient=alice,
                admin=admin,
                subject="Welcome to SwapWing Staging",
                body=(
                    "You're set up with seeded data so the Flutter and Django apps can "
                    "exercise journeys and challenges end-to-end."
                ),
            )
            self._ensure_notification(
                recipient=ben,
                admin=admin,
                subject="Challenge Kickoff",
                body="Jump into the Sustainable Swaps challenge and post your next trade-up step!",
            )

        self.stdout.write(self.style.SUCCESS("Staging data ensured."))

    # --- helpers -----------------------------------------------------------------
    def _ensure_admin_user(self):
        User = get_user_model()
        admin, created = User.objects.get_or_create(
            email="admin@swapwing.test",
            defaults={
                "first_name": "SwapWing",
                "last_name": "Admin",
                "is_active": True,
            },
        )
        if created:
            admin.set_password("changeme")
        admin.staff = True
        admin.admin = True
        admin.email_verified = True
        admin.save()

        admin_info, _ = AdminInfo.objects.get_or_create(
            user=admin,
            defaults={
                "about_me": "Operations contact for SwapWing staging.",
                "phone": "+15555550100",
                "verified": True,
                "profile_complete": True,
            },
        )
        Wallet.objects.get_or_create(user=admin, defaults={"currency": "USD", "balance": "0"})
        return admin_info

    def _ensure_trader(self, email, first_name, last_name, bio):
        User = get_user_model()
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                "first_name": first_name,
                "last_name": last_name,
                "is_active": True,
            },
        )
        if created:
            user.set_password("tradeup123")
        user.email_verified = True
        user.save()

        try:
            personal_info: PersonalInfo = user.user_personal_info  # type: ignore[attr-defined]
        except PersonalInfo.DoesNotExist:  # type: ignore[attr-defined]
            personal_info = PersonalInfo.objects.create(user=user, active=True)
        personal_info.about_me = bio
        personal_info.profile_complete = True
        personal_info.verified = True
        personal_info.active = True
        personal_info.phone = personal_info.phone or "+15555550000"
        personal_info.save()

        Wallet.objects.get_or_create(
            user=user,
            defaults={
                "currency": "USD",
                "balance": str(random.randint(50, 200)),
                "bonus": "10",
            },
        )
        SocialMedia.objects.get_or_create(
            user=user,
            name="Instagram",
            defaults={"link": f"https://instagram.com/{first_name.lower()}trades", "active": True},
        )
        SocialMedia.objects.get_or_create(
            user=user,
            name="Youtube",
            defaults={"link": f"https://youtube.com/@{first_name.lower()}TradeUp"},
        )
        return user

    def _get_or_create_tag(self, name, admin_info):
        tag, _ = Tag.objects.get_or_create(name=name, defaults={"user": admin_info.user})
        return tag

    def _ensure_episode(self, title, author, summary, tags, shared_with):
        episode, _ = Episode.objects.get_or_create(
            title=title,
            user=author,
            defaults={
                "caption": summary,
                "date_published": timezone.now() - timedelta(days=3),
                "active": True,
                "views": random.randint(100, 500),
                "trending_no": random.randint(1, 5),
            },
        )
        episode.caption = summary
        episode.active = True
        if not episode.date_published:
            episode.date_published = timezone.now() - timedelta(days=3)
        episode.views = episode.views or random.randint(100, 500)
        episode.trending_no = episode.trending_no or random.randint(1, 5)
        episode.save()
        episode.tags.set(tags)
        episode.shared_episodes.set(shared_with)
        return episode

    def _ensure_notification(self, recipient, admin, subject, body):
        notification, created = Notification.objects.get_or_create(
            user=recipient,
            subject=subject,
            defaults={
                "body": body,
                "notification_admin": admin,
                "active": True,
            },
        )
        if not created:
            notification.body = body
            notification.notification_admin = admin
            notification.active = True
            notification.save()

    def _ensure_challenge(self, participants):
        defaults = {
            "description": "Rack up the most eco-friendly trade-ups in two weeks.",
            "cta_copy": "Join the sprint and climb the leaderboard.",
            "status": ChallengeStatus.ACTIVE,
            "category": ChallengeCategory.SUSTAINABILITY,
            "start_at": timezone.now() - timedelta(days=2),
            "end_at": timezone.now() + timedelta(days=5),
        }
        challenge, created = Challenge.objects.get_or_create(
            title="Sustainable Swap Sprint",
            defaults=defaults,
        )
        if not created:
            for field, value in defaults.items():
                setattr(challenge, field, value)
            challenge.save(update_fields=list(defaults.keys()) + ["updated_at"])

        ChallengeMilestone.objects.get_or_create(
            challenge=challenge,
            label="Hit $100 in value",
            defaults={"target_value": Decimal("100.00"), "order": 1},
        )
        ChallengeMilestone.objects.get_or_create(
            challenge=challenge,
            label="Break $250",
            defaults={"target_value": Decimal("250.00"), "order": 2},
        )

        ChallengePrize.objects.get_or_create(
            challenge=challenge,
            name="Top Trader",
            defaults={
                "description": "Feature in the newsletter and 200 swap credits.",
                "rank_start": 1,
                "rank_end": 1,
                "order": 1,
            },
        )
        ChallengePrize.objects.get_or_create(
            challenge=challenge,
            name="Community Favorite",
            defaults={
                "description": "Badge and merch kit for top three traders.",
                "rank_start": 2,
                "rank_end": 3,
                "order": 2,
            },
        )

        for idx, user in enumerate(participants, start=1):
            defaults = {
                "total_trade_delta": Decimal("160.00") - Decimal(30 * idx),
                "trades_completed": 1 + idx,
                "last_progress_at": timezone.now() - timedelta(hours=idx * 6),
            }
            participation, created = ChallengeParticipation.objects.get_or_create(
                challenge=challenge,
                user=user,
                defaults=defaults,
            )
            if not created:
                for field, value in defaults.items():
                    setattr(participation, field, value)
                participation.save(update_fields=list(defaults.keys()) + ["updated_at"])
