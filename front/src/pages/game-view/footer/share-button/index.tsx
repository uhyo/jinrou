import React, { useMemo, useState } from 'react';
import { Button } from '../../../../common/forms/button';
import { FontAwesomeIcon } from '../../../../util/icon';
import { useI18n } from '../../../../i18n/react';
import { ShareButtonConfig } from '../../defs';

// definition of Web Share API's share function
declare global {
  interface Navigator {
    canShare?(data?: { url?: string; text?: string; title?: string }): boolean;
    share(data: { url?: string; text?: string; title?: string }): Promise<void>;
  }
}

interface ShareButtonProps {
  roomName: string;
  shareButton: ShareButtonConfig;
}

export const ShareButton: React.FunctionComponent<ShareButtonProps> = ({
  roomName,
  shareButton,
}) => {
  const t = useI18n('game_client');
  const shareData = useMemo(
    () => ({
      url: location.href,
      title: roomName,
    }),
    [roomName],
  );
  const [dontUseWebShare, setDontUseWebShare] = useState(false);
  const webShareAvailable = useMemo(
    () => {
      if (dontUseWebShare) {
        return false;
      }
      if (navigator.canShare == null) {
        return !!navigator.share;
      }
      return navigator.canShare(shareData);
    },
    [shareData, dontUseWebShare],
  );

  if (webShareAvailable) {
    const clickHandler = () => {
      navigator.share!(shareData).catch(err => {
        console.error(err);
        if (/internal error/i.test(err.message)) {
          // Fallback for Linux Chrome Desktop
          setDontUseWebShare(true);
        }
      });
    };
    return (
      <Button type="button" onClick={clickHandler}>
        <FontAwesomeIcon icon={['fas', 'share-alt']} /> {t('share.title')}
      </Button>
    );
  } else if (shareButton.twitter) {
    const clickHandler = () => {
      window.open(
        `https://twitter.com/intent/tweet?text=${encodeURIComponent(
          roomName,
        )}&url=${encodeURIComponent(location.href)}`,
      );
    };
    return (
      <Button onClick={clickHandler}>
        <FontAwesomeIcon icon={['fab', 'twitter']} /> {t('share.title')}
      </Button>
    );
  }
  return null;
};
