```name```
- Name of this theme，String。

```opening```
- Opening wording，String。Comes after 「1日目の夜になりました。」

```vote```, ```sunrise```, ```sunset```, ```icon```, ```background_color```, ```color```
- Not really used...

```skins```
- JSON, ```key``` of which should be unique.

```skins.some_character```
- JSON

```skins.some_character.avatar```
- Link, or an ```Array``` of link of players icon. 

- Aspect ratio of avatar should be best 1:1

```skins.some_character.name```
- Name, necessary, ```String```。

```skins.some_character.prize```
- Prize, optional, ```String``` or ```Array of String```.

- Prize could be empty.

- If both ```skins.some_character.avatar``` and ```skins.some_character.prize``` are Array, the avatar and title are randomly selected independently.

```skin_tip```
- ```String```. To show player who he is. ```skin_tip```is the title of this dialog, use something like 「Student card」, 「Driver license」 etc.

```lockable```
- ```Boolean```. If you want this room cannot be locked, set this to be ```true```. Default is ```false```.

```isAvailable```
- ```Function```.
