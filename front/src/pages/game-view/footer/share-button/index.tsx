import React, { useMemo } from 'react';
import { Button } from '../../../../common/forms/button';
import { FontAwesomeIcon } from '../../../../util/icon';
import { useI18n } from '../../../../i18n/react';
import { ShareButtonConfig } from '../../defs';

// definition of Web Share API's share function
declare global {
  interface Navigator {
    canShare?(data?: { url?: string; text?: string; title?: string }): boolean;
    share?(data: {
      url?: string;
      text?: string;
      title?: string;
    }): Promise<void>;
  }
}

interface ShareButtonProps {
  shareButton: ShareButtonConfig;
}

export const ShareButton: React.FunctionComponent<ShareButtonProps> = ({
  shareButton,
}) => {
  const t = useI18n('game_client');
  const webShareAvailable = useMemo(() => {
    if (navigator.canShare == null) {
      return !!navigator.share;
    }
    return navigator.canShare();
  }, []);

  if (webShareAvailable) {
    return (
      <Button>
        <FontAwesomeIcon icon={['fas', 'share-alt']} /> {t('share.title')}
      </Button>
    );
  } else if (shareButton.twitter) {
    return (
      <Button>
        <FontAwesomeIcon icon={['fab', 'twitter']} /> {t('share.title')}
      </Button>
    );
  }
  return null;
};
