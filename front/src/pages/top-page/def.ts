interface LoginQuery {
  userId: string;
  password: string;
  rememberMe?: boolean;
}

interface SignupQuery {
  userId: string;
  password: string;
}

/**
 * Type of login handler.
 */
export type LoginHandler = (
  query: LoginQuery,
) => Promise<{
  error?: 'loginError';
}>;

/**
 * Type of signup handler.
 */
export type SignupHandler = (
  query: SignupQuery,
) => Promise<{
  error?: string;
}>;
