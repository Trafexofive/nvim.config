local M = {}

-- Template for a basic block mod
M.block_template = {
  java = [[package {{PACKAGE_NAME}};

import net.fabricmc.fabric.api.item.v1.FabricItemSettings;
import net.fabricmc.fabric.api.object.builder.v1.block.FabricBlockSettings;
import net.minecraft.block.Block;
import net.minecraft.block.Material;
import net.minecraft.item.BlockItem;
import net.minecraft.item.ItemGroup;
import net.minecraft.util.Identifier;
import net.minecraft.util.registry.Registry;

public class {{CLASS_NAME}} {
	public static final Block EXAMPLE_BLOCK = new Block(FabricBlockSettings.of(Material.STONE).strength(4.0f));

	public static void registerBlocks() {
		Registry.register(Registry.BLOCK, new Identifier("{{MOD_ID}}", "{{BLOCK_ID}}"), EXAMPLE_BLOCK);
		Registry.register(Registry.ITEM, new Identifier("{{MOD_ID}}", "{{BLOCK_ID}}"), 
			new BlockItem(EXAMPLE_BLOCK, new FabricItemSettings().group(ItemGroup.BUILDING_BLOCKS)));
	}
}
]],
  resources = {
    ["blockstates/{{BLOCK_ID}}.json"] = [[{
  "variants": {
    "": { "model": "{{MOD_ID}}:block/{{BLOCK_ID}}" }
  }
}]],
    ["models/block/{{BLOCK_ID}}.json"] = [[{
  "parent": "block/cube_all",
  "textures": {
    "all": "{{MOD_ID}}:blocks/{{BLOCK_ID}}"
  }
}]],
    ["models/item/{{BLOCK_ID}}.json"] = [[{
  "parent": "{{MOD_ID}}:block/{{BLOCK_ID}}"
}]]
  }
}

-- Template for a basic item mod
M.item_template = {
  java = [[package {{PACKAGE_NAME}};

import net.fabricmc.fabric.api.item.v1.FabricItemSettings;
import net.minecraft.item.Item;
import net.minecraft.item.ItemGroup;
import net.minecraft.util.Identifier;
import net.minecraft.util.registry.Registry;

public class {{CLASS_NAME}} {
	public static final Item EXAMPLE_ITEM = new Item(new FabricItemSettings().group(ItemGroup.MISC));

	public static void registerItems() {
		Registry.register(Registry.ITEM, new Identifier("{{MOD_ID}}", "{{ITEM_ID}}"), EXAMPLE_ITEM);
	}
}
]],
  resources = {
    ["models/item/{{ITEM_ID}}.json"] = [[{
  "parent": "item/generated",
  "textures": {
    "layer0": "{{MOD_ID}}:items/{{ITEM_ID}}"
  }
}]]
  }
}

-- Template for a basic entity mod
M.entity_template = {
  java = [[package {{PACKAGE_NAME}};

import net.fabricmc.fabric.api.object.builder.v1.entity.FabricDefaultAttributeRegistry;
import net.fabricmc.fabric.api.object.builder.v1.entity.FabricEntityTypeBuilder;
import net.minecraft.entity.EntityDimensions;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.SpawnGroup;
import net.minecraft.util.Identifier;
import net.minecraft.util.registry.Registry;

public class {{CLASS_NAME}} {
	public static final EntityType<ExampleEntity> EXAMPLE_ENTITY = FabricEntityTypeBuilder.create(SpawnGroup.CREATURE, ExampleEntity::new)
			.dimensions(EntityDimensions.fixed(1.0f, 1.0f)).build();

	public static void registerEntities() {
		Registry.register(Registry.ENTITY_TYPE, new Identifier("{{MOD_ID}}", "{{ENTITY_ID}}"), EXAMPLE_ENTITY);
		FabricDefaultAttributeRegistry.register(EXAMPLE_ENTITY, ExampleEntity.createExampleAttributes());
	}
}
]],
  resources = {
    ["lang/en_us.json"] = [[{
  "entity.{{MOD_ID}}.{{ENTITY_ID}}": "{{ENTITY_NAME}}"
}]]
  }
}

-- Template for a basic screen/GUI mod
M.screen_template = {
  java = [[package {{PACKAGE_NAME}};

import net.minecraft.client.gui.screen.Screen;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.text.Text;

public class {{CLASS_NAME}} extends Screen {
	protected {{CLASS_NAME}}(Text title) {
		super(title);
	}

	@Override
	public void render(MatrixStack matrices, int mouseX, int mouseY, float delta) {
		this.renderBackground(matrices);
		drawCenteredText(matrices, this.textRenderer, this.title, this.width / 2, 15, 16777215);
		super.render(matrices, mouseX, mouseY, delta);
	}
}
]]
}

return M