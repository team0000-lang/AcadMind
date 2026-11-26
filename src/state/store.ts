import type { Language } from './i18n';
import { getLanguage, setLanguage } from './i18n';

export type View = 'splash' | 'login' | 'register' | 'phone' | 'otp' | 'verify' | 'reset' | 'onboarding' | 'home' | 'subjects' | 'subject-detail' | 'schedule' | 'notifications' | 'profile' | 'settings' | 'owner';
export type Theme = 'light' | 'dark' | 'system';

export interface AppState {
  view: View;
  theme: Theme;
  language: Language;
  previewMode: boolean;
  selectedSubjectId: string;
  scheduleTab: 'Today' | 'Tomorrow' | 'Weekly' | 'Upcoming';
  onboarding: { year: string; group: string; section: string };
  reminderMinutes: number;
  notificationsEnabled: boolean;
  mandatoryUpdate: boolean;
}

const storedTheme = (localStorage.getItem('am-theme') as Theme | null) ?? 'light';
const storedLanguage = (localStorage.getItem('am-language') as Language | null) ?? 'en';
setLanguage(storedLanguage);

let state: AppState = {
  view: 'splash', theme: storedTheme, language: storedLanguage, previewMode: true, selectedSubjectId: 'physics', scheduleTab: 'Today',
  onboarding: { year: 'First Year', group: 'G1', section: 'Sec 3' }, reminderMinutes: 10, notificationsEnabled: true, mandatoryUpdate: false
};

const listeners = new Set<(state: AppState) => void>();
export function getState() { return state; }
export function subscribe(listener: (state: AppState) => void) { listeners.add(listener); return () => listeners.delete(listener); }
export function updateState(patch: Partial<AppState>) { state = { ...state, ...patch }; listeners.forEach((listener) => listener(state)); }
export function navigate(view: View) { updateState({ view }); window.scrollTo({ top: 0, behavior: 'smooth' }); }
export function setTheme(theme: Theme) { localStorage.setItem('am-theme', theme); updateState({ theme }); }
export function setAppLanguage(language: Language) { localStorage.setItem('am-language', language); setLanguage(language); updateState({ language }); }
export function setSubject(id: string) { updateState({ selectedSubjectId: id, view: 'subject-detail' }); }
export function setScheduleTab(scheduleTab: AppState['scheduleTab']) { updateState({ scheduleTab }); }
export function updateOnboarding(patch: Partial<AppState['onboarding']>) { updateState({ onboarding: { ...state.onboarding, ...patch } }); }
