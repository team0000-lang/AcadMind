export interface AuthCredentials { email: string; password: string; remember: boolean; }
export interface RegistrationInput { name: string; email: string; phone: string; password: string; }

/** Phase 1 intentionally does not create a real authenticated session. */
export class PreviewAuthService {
  async login(_credentials: AuthCredentials): Promise<{ ok: false; reason: 'backend-not-connected' }> {
    return { ok: false, reason: 'backend-not-connected' };
  }
  async register(_input: RegistrationInput): Promise<{ ok: false; reason: 'backend-not-connected' }> {
    return { ok: false, reason: 'backend-not-connected' };
  }
  async requestPasswordReset(_email: string): Promise<{ ok: false; reason: 'backend-not-connected' }> {
    return { ok: false, reason: 'backend-not-connected' };
  }
}
export const authService = new PreviewAuthService();
