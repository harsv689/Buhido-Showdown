Assets {
  Id: 5206664244653592263
  Name: "Custom Burning Wood"
  PlatformAssetType: 13
  SerializationVersion: 125
  CustomMaterialAsset {
    BaseMaterialId: 16325962649651067789
    ParameterOverrides {
      Overrides {
        Name: "u_tiles"
        Float: 0.25
      }
      Overrides {
        Name: "v_tiles"
        Float: 0.25
      }
    }
    Assets {
      Id: 16325962649651067789
      Name: "Burning Wood"
      PlatformAssetType: 2
      PrimaryAsset {
        AssetType: "MaterialAssetRef"
        AssetId: "fxmi_burning_erode"
      }
    }
  }
}
