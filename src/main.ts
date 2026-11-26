import './styles.css';
import { mockRepositories } from './services/repositories';
import { getState, navigate, setAppLanguage, setScheduleTab, setSubject, setTheme, subscribe, updateOnboarding, updateState } from './state/store';
import { renderApp, tickCountdown } from './ui/render';
import { t } from './state/i18n';

const app = document.querySelector<HTMLDivElement>('#app');
let toastTimer: number | undefined;

function showToast(message: string, tone: 'default' | 'success' = 'default') {
  document.querySelector('.toast')?.remove();
  const toast = document.createElement('div');
  toast.className = `toast ${tone}`;
  toast.innerHTML = `<span class="toast-check">${tone === 'success' ? '✓' : 'i'}</span><span>${message}</span>`;
  document.body.appendChild(toast);
  window.clearTimeout(toastTimer);
  toastTimer = window.setTimeout(() => toast.remove(), 3300);
}

function render() { renderApp(getState()); }
subscribe(render);
render();

window.setTimeout(() => {
  if (getState().view === 'splash') navigate('login');
}, 1700);
window.setInterval(tickCountdown, 1000);

app?.addEventListener('click', async (event) => {
  const target = event.target as HTMLElement;
  const viewTarget = target.closest<HTMLElement>('[data-view]');
  const actionTarget = target.closest<HTMLElement>('[data-action]');
  const subjectTarget = target.closest<HTMLElement>('[data-subject]');
  const scheduleTarget = target.closest<HTMLElement>('[data-schedule-tab]');
  const languageTarget = target.closest<HTMLElement>('[data-language]');
  const themeTarget = target.closest<HTMLElement>('[data-theme]');
  const yearTarget = target.closest<HTMLElement>('[data-onboard-year]');
  const groupTarget = target.closest<HTMLElement>('[data-onboard-group]');
  const sectionTarget = target.closest<HTMLElement>('[data-onboard-section]');

  if (viewTarget) {
    const view = viewTarget.dataset.view;
    if (view && ['login', 'register', 'phone', 'otp', 'verify', 'reset', 'onboarding', 'home', 'subjects', 'schedule', 'notifications', 'profile', 'settings', 'owner'].includes(view)) {
      navigate(view as Parameters<typeof navigate>[0]);
      document.body.classList.remove('nav-open');
      return;
    }
  }
  if (subjectTarget?.dataset.subject) { setSubject(subjectTarget.dataset.subject); return; }
  if (scheduleTarget?.dataset.scheduleTab) { setScheduleTab(scheduleTarget.dataset.scheduleTab as Parameters<typeof setScheduleTab>[0]); return; }
  if (languageTarget?.dataset.language) { setAppLanguage(languageTarget.dataset.language as 'en' | 'ar'); showToast(languageTarget.dataset.language === 'ar' ? 'تم تبديل اللغة إلى العربية' : 'Language changed to English', 'success'); return; }
  if (themeTarget?.dataset.theme) { setTheme(themeTarget.dataset.theme as Parameters<typeof setTheme>[0]); showToast('Theme preference saved locally', 'success'); return; }
  if (yearTarget?.dataset.onboardYear) { updateOnboarding({ year: yearTarget.dataset.onboardYear }); return; }
  if (groupTarget?.dataset.onboardGroup) { updateOnboarding({ group: groupTarget.dataset.onboardGroup }); return; }
  if (sectionTarget?.dataset.onboardSection) { updateOnboarding({ section: sectionTarget.dataset.onboardSection }); return; }

  if (!actionTarget) return;
  const action = actionTarget.dataset.action;
  if (action === 'preview') { navigate('onboarding'); return; }
  if (action === 'login-attempt' || action === 'register-attempt') { showToast('Authentication is intentionally waiting for the Phase 2 backend. Use Preview student experience to explore safely.'); return; }
  if (action === 'toggle-password') {
    const input = actionTarget.parentElement?.querySelector('input');
    if (input) input.type = input.type === 'password' ? 'text' : 'password';
    return;
  }
  if (action === 'toggle-language') { setAppLanguage(getState().language === 'en' ? 'ar' : 'en'); return; }
  if (action === 'toggle-mobile-nav') { document.body.classList.add('nav-open'); return; }
  if (action === 'close-mobile-nav') { document.body.classList.remove('nav-open'); return; }
  if (action === 'dismiss-banner') { actionTarget.closest('.preview-banner')?.remove(); return; }
  if (action === 'mark-read') { await mockRepositories.notifications.markAllRead(); showToast('All notifications marked as read', 'success'); render(); return; }
  if (action === 'logout') { navigate('login'); showToast('Preview mode ended'); return; }
  if (action === 'show-update') { updateState({ mandatoryUpdate: true }); return; }
  if (action === 'close-update') { updateState({ mandatoryUpdate: false }); return; }
  if (action === 'ai') { showToast('AM AI is ready for the Phase 2 knowledge connection.'); return; }
  if (action === 'add-schedule' || action === 'add-content') { showToast('Owner action is prepared for the Phase 2 data connection.'); return; }
  if (action === 'edit-profile' || action === 'change-password') { showToast('This form is ready for the Phase 2 account service.'); return; }
  if (action === 'open-lecture' || action === 'open-schedule') { showToast('Detail navigation is ready for connected content.'); return; }
  if (action === 'retry') { showToast(t('loading')); return; }
}
);

app?.addEventListener('change', (event) => {
  const target = event.target as HTMLInputElement;
  if (target.matches('[data-toggle-notifications]')) { updateState({ notificationsEnabled: target.checked }); showToast(target.checked ? 'Lecture reminders enabled' : 'Lecture reminders paused', 'success'); }
  if (target.matches('[data-reminder-range]')) { updateState({ reminderMinutes: Number(target.value) }); showToast(`Reminder set to ${target.value} minutes`, 'success'); }
});

app?.addEventListener('input', (event) => {
  const target = event.target as HTMLInputElement;
  if (target.matches('[data-reminder-range]')) {
    const output = document.querySelector('output');
    if (output) output.textContent = `${target.value} min`;
  }
});
