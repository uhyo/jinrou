// Init Font Awesome icons.
import fontawesome from '@fortawesome/fontawesome';
import {
    faQuestionCircle,
    faIdCard,
} from '@fortawesome/fontawesome-free-regular';
import {
    faPlusSquare,
    faMinusSquare,
    faSquare,
    faFolder,
    faFolderOpen,
    faSpinner,
    faLock,
    faUnlockAlt,
    faInfoCircle,
    faTimes,
    faUser,
    faUserTimes,
    faBan,
} from '@fortawesome/fontawesome-free-solid';

fontawesome.library.add(
    faQuestionCircle,
    faIdCard,
    faPlusSquare,
    faMinusSquare,
    faSquare,
    faFolder,
    faFolderOpen,
    faSpinner,
    faLock,
    faUnlockAlt,
    faInfoCircle,
    faTimes,
    faUser,
    faUserTimes,
    faBan,
);

// Publish to global.
(window as any).FontAwesome = fontawesome;

