import type { AuthError, User } from '@supabase/supabase-js';
import { requireSupabase } from './supabase';

export interface AuthCredentials { email: string; password: string; remember: boolean; }
export interface RegistrationInput { name: string; email: string; phone: string; password: string; }
export interface AuthResult { user: User | null; error: AuthError | null; }

export class SupabaseAuthService {
  async login({ email, password }: AuthCredentials): Promise<AuthResult> {
    const { data, error } = await requireSupabase().auth.signInWithPassword({ email: email.trim(), password });
    return { user: data.user, error };
  }

  async register(input: RegistrationInput): Promise<AuthResult> {
    const { data, error } = await requireSupabase().auth.signUp({
      email: input.email.trim(),
      password: input.password,
      options: { data: { full_name: input.name.trim(), phone: input.phone.trim() } }
    });
    return { user: data.user, error };
  }

  async requestPasswordReset(email: string, redirectTo?: string): Promise<{ error: AuthError | null }> {
    const { error } = await requireSupabase().auth.resetPasswordForEmail(email.trim(), redirectTo ? { redirectTo } : undefined);
    return { error };
  }

  async sendPhoneOtp(phone: string, fullName?: string): Promise<{ error: AuthError | null }> {
    const { error } = await requireSupabase().auth.signInWithOtp({
      phone: phone.trim(),
      options: { shouldCreateUser: true, ...(fullName ? { data: { full_name: fullName.trim() } } : {}) }
    });
    return { error };
  }

  async verifyPhoneOtp(phone: string, token: string): Promise<AuthResult> {
    const { data, error } = await requireSupabase().auth.verifyOtp({ phone: phone.trim(), token: token.trim(), type: 'sms' });
    return { user: data.user, error };
  }

  async logout(): Promise<{ error: AuthError | null }> {
    const { error } = await requireSupabase().auth.signOut();
    return { error };
  }

  async getSession() {
    return requireSupabase().auth.getSession();
  }

  onAuthStateChange(callback: Parameters<ReturnType<typeof requireSupabase>['auth']['onAuthStateChange']>[0]) {
    return requireSupabase().auth.onAuthStateChange(callback);
  }
}

export const authService = new SupabaseAuthService();
