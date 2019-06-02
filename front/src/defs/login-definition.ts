export interface LoginQuery {
  userId: string;
  password: string;
  rememberMe?: boolean;
}
/**
 * Type of login handler.
 */
export type LoginHandler = (
  query: LoginQuery,
) => Promise<{
  error?: 'loginError';
}>;
