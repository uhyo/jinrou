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
} from '@fortawesome/fontawesome-free-solid';

fontawesome.library.add(
    faQuestionCircle,
    faPlusSquare,
    faMinusSquare,
    faSpinner,
);

// Publish to global.
(window as any).FontAwesome = fontawesome;

