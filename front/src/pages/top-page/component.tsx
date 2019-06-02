import * as React from 'react';
import { i18n } from '../../i18n';
import { LoginHandler } from './def';

interface Props {
  i18n: i18n;
  onLogin: LoginHandler;
}
export const TopPage = ({ i18n }: Props) => <div>Top page</div>;
