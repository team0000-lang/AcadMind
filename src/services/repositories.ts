import { notifications, schedule, subjects, student } from '../data/mock';
import type { NotificationItem, ScheduleItem, StudentProfile, Subject } from '../data/mock';

export interface ProfileRepository { getProfile(): Promise<StudentProfile>; updateProfile(input: Partial<StudentProfile>): Promise<StudentProfile>; }
export interface SubjectRepository { list(): Promise<Subject[]>; getById(id: string): Promise<Subject | undefined>; }
export interface ScheduleRepository { list(): Promise<ScheduleItem[]>; }
export interface NotificationRepository { list(): Promise<NotificationItem[]>; markAllRead(): Promise<void>; }

export const mockRepositories = {
  profile: { async getProfile() { return student; }, async updateProfile(input: Partial<StudentProfile>) { Object.assign(student, input); return student; } } satisfies ProfileRepository,
  subjects: { async list() { return subjects; }, async getById(id: string) { return subjects.find((subject) => subject.id === id); } } satisfies SubjectRepository,
  schedule: { async list() { return schedule; } } satisfies ScheduleRepository,
  notifications: { async list() { return notifications; }, async markAllRead() { notifications.forEach((item) => { item.unread = false; }); } } satisfies NotificationRepository
};
